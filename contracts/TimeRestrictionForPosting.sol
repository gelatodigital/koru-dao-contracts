// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {IKoruDao} from "./interfaces/IKoruDao.sol";
import {IKoruDaoRestriction} from "./interfaces/IKoruDaoRestriction.sol";
import {
    IERC721MetaTxEnumerableUpgradeable
} from "./interfaces/IERC721MetaTxEnumerableUpgradeable.sol";

//solhint-disable not-rely-on-time
contract TimeRestrictionForPosting is IKoruDaoRestriction {
    uint256 public immutable actionInterval;
    address public immutable koruDao;
    IERC721MetaTxEnumerableUpgradeable public immutable koruDaoNft;

    mapping(bytes32 => uint256) public lastActionTime;

    modifier onlyKoruDao() {
        require(
            msg.sender == koruDao,
            "TimeRestrictionForPosting: Only KoruDao"
        );
        _;
    }

    constructor(
        uint256 _actionInterval,
        address _koruDao,
        IERC721MetaTxEnumerableUpgradeable _koruDaoNft
    ) {
        actionInterval = _actionInterval;
        koruDao = _koruDao;
        koruDaoNft = _koruDaoNft;
    }

    function checkAndUpdateRestriction(address _user, uint256 _action)
        external
        override
        onlyKoruDao
        returns (uint256 token)
    {
        token = getKoruDaoNftTokenId(_user);
        checkRestriction(token, _action);

        bytes32 tokenActionHash = keccak256(abi.encode(token, _action));

        lastActionTime[tokenActionHash] = block.timestamp;
    }

    function lastPost(uint256 _token) external view returns (uint256) {
        bytes32 tokenActionHash = keccak256(
            abi.encode(_token, uint256(IKoruDao.Action.POST))
        );

        return lastActionTime[tokenActionHash];
    }

    function checkRestriction(uint256 _token, uint256 _action)
        public
        view
        override
    {
        bytes32 tokenActionHash = keccak256(abi.encode(_token, _action));

        require(
            (block.timestamp - lastActionTime[tokenActionHash] >=
                actionInterval),
            "TimeRestrictionForPosting: Too frequent"
        );
    }

    function getKoruDaoNftTokenId(address _user)
        public
        view
        override
        returns (uint256 token)
    {
        require(
            koruDaoNft.balanceOf(_user) > 0,
            "TimeRestrictionForPosting: No KoruDaoNft"
        );

        token = koruDaoNft.tokenOfOwnerByIndex(_user, 0);
    }

    /// @dev can be added as desired
    // function lastFollow(uint256 _token) external view returns (uint256) {
    //     bytes32 tokenActionHash = keccak256(
    //         abi.encode(_token, uint256(IKoruDao.Action.FOLLOW))
    //     );

    //     return lastActionTime[tokenActionHash];
    // }

    // function lastMirror(uint256 _token) external view returns (uint256) {
    //     bytes32 tokenActionHash = keccak256(
    //         abi.encode(_token, uint256(IKoruDao.Action.MIRROR))
    //     );

    //     return lastActionTime[tokenActionHash];
    // }
}
