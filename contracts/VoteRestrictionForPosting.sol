// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {IKoruDao} from "./interfaces/IKoruDao.sol";
import {IKoruDaoRestriction} from "./interfaces/IKoruDaoRestriction.sol";
import {
    IERC721MetaTxEnumerableUpgradeable
} from "./interfaces/IERC721MetaTxEnumerableUpgradeable.sol";
import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {DataTypes} from "./libraries/LensDataTypes.sol";
import {IKoruDao} from "./interfaces/IKoruDao.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

//solhint-disable not-rely-on-time
//solhint-disable max-states-count
/// @dev requires other NFT token holders to have upvoted the post before
/// it can be posted
contract VoteRestrictionForPosting is ERC2771Context {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public immutable actionInterval;
    address public immutable koruDao;
    IERC721MetaTxEnumerableUpgradeable public immutable koruDaoNft;
    uint256 public immutable koruDaoProfileId;

    int256 public voteThreshold;
    mapping(bytes32 => uint256) public lastActionTime;
    mapping(bytes32 => int256) public votes;
    mapping(bytes32 => bytes32) public postDataByTokenAction;
    mapping(bytes32 => EnumerableSet.AddressSet) private _voters;

    event LogAddToQueue(
        address indexed user,
        uint256 indexed token,
        bytes32 indexed postDataHash,
        uint256 timestamp
    );

    modifier onlyKoruDao() {
        require(
            msg.sender == koruDao,
            "VoteRestrictionForPosting: Only KoruDao"
        );
        _;
    }

    modifier onlyGelatoRelay() {
        require(isTrustedForwarder(msg.sender), "KoruDao: Only GelatoRelay");
        _;
    }

    constructor(
        address _gelatoRelay,
        uint256 _actionInterval,
        int256 _voteThreshold,
        address _koruDao,
        IERC721MetaTxEnumerableUpgradeable _koruDaoNft,
        uint256 _koruDaoProfileId
    ) ERC2771Context(_gelatoRelay) {
        actionInterval = _actionInterval;
        voteThreshold = _voteThreshold;
        koruDao = _koruDao;
        koruDaoNft = _koruDaoNft;
        koruDaoProfileId = _koruDaoProfileId;
    }

    function addToQueue(DataTypes.PostData calldata _postData)
        external
        onlyGelatoRelay
    {
        require(
            _postData.profileId == koruDaoProfileId,
            "VoteRestrictionForPosting: Only post for KoruDao"
        );

        address user = _msgSender();
        uint256 token = getKoruDaoNftTokenId(user);

        bytes32 tokenActionHash = keccak256(
            abi.encode(token, IKoruDao.Action.POST)
        );

        // Check that NFT did not post since lastActionTime
        checkTimeRestriction(tokenActionHash);

        // Update lastActionTime
        lastActionTime[tokenActionHash] = block.timestamp;

        // Reset votes for postDataHash
        bytes32 postDataHash = keccak256(abi.encode(_postData, user));
        delete votes[postDataHash];
        delete _voters[postDataHash];

        // Store new post from token holder
        postDataByTokenAction[tokenActionHash] = postDataHash;

        emit LogAddToQueue(user, token, postDataHash, block.timestamp);
    }

    function checkAndUpdateRestriction(address _user, uint256 _action)
        external
        onlyKoruDao
        returns (uint256 token)
    {
        token = getKoruDaoNftTokenId(_user);

        bytes32 tokenActionHash = keccak256(abi.encode(token, _action));
        bytes32 postDataHash = postDataByTokenAction[tokenActionHash];
        checkVoteRestriction(postDataHash);

        delete postDataByTokenAction[tokenActionHash];
        delete votes[postDataHash];
        delete _voters[postDataHash];
    }

    function upvote(bytes32 _postDataHash) external onlyGelatoRelay {
        address user = _msgSender();
        uint256 votingPower = getKoruDaoNftVotingPower(user);

        if (_voters[_postDataHash].contains(user))
            revert("VoteRestrictionForPosting: Already voted");

        _voters[_postDataHash].add(user);
        votes[_postDataHash] += int256(votingPower);
    }

    function downvoted(bytes32 _postDataHash) external onlyGelatoRelay {
        address user = _msgSender();
        uint256 votingPower = getKoruDaoNftVotingPower(user);

        if (_voters[_postDataHash].contains(user))
            revert("VoteRestrictionForPosting: Already voted");

        _voters[_postDataHash].add(user);
        votes[_postDataHash] -= int256(votingPower);
    }

    function getLastPost(uint256 _token) external view returns (uint256) {
        bytes32 tokenActionHash = keccak256(
            abi.encode(_token, uint256(IKoruDao.Action.POST))
        );

        return lastActionTime[tokenActionHash];
    }

    function getPostVotes(bytes32 _postDataHash)
        external
        view
        returns (int256)
    {
        return votes[_postDataHash];
    }

    function checkTimeRestriction(bytes32 _tokenActionHash) public view {
        require(
            (block.timestamp - lastActionTime[_tokenActionHash] >=
                actionInterval),
            "VoteRestrictionForPosting: Too frequent"
        );
    }

    function checkVoteRestriction(bytes32 _postDataHash) public view {
        int256 postVotes = votes[_postDataHash];

        require(
            postVotes >= voteThreshold,
            "VoteRestrictionForPosting: Insufficient upvotes"
        );
    }

    function getKoruDaoNftTokenId(address _user)
        public
        view
        returns (uint256 token)
    {
        require(
            koruDaoNft.balanceOf(_user) > 0,
            "VoteRestrictionForPosting: No KoruDaoNft"
        );

        token = koruDaoNft.tokenOfOwnerByIndex(_user, 0);
    }

    function getKoruDaoNftVotingPower(address _user)
        public
        view
        returns (uint256 votingPower)
    {
        votingPower = koruDaoNft.balanceOf(_user);
        require(votingPower > 0, "VoteRestrictionForPosting: No KoruDaoNft");
    }
}
