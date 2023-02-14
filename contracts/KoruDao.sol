// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {
    ERC721Holder
} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {DataTypes} from "./libraries/LensDataTypes.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";
import {IKoruDao} from "./interfaces/IKoruDao.sol";
import {IKoruDaoRestriction} from "./interfaces/IKoruDaoRestriction.sol";

//solhint-disable not-rely-on-time
contract KoruDao is ERC721Holder, ERC2771Context, Proxied, IKoruDao {
    ILensHub public immutable lensHub;
    uint256 public immutable koruDaoProfileId;

    mapping(Action => address) public actionRestriction;

    modifier onlyGelatoRelay() {
        require(isTrustedForwarder(msg.sender), "KoruDao: Only GelatoRelay");
        _;
    }

    constructor(
        address _gelatoRelay,
        ILensHub _lensHub,
        uint256 _koruDaoProfileId
    ) ERC2771Context(_gelatoRelay) {
        lensHub = _lensHub;
        koruDaoProfileId = _koruDaoProfileId;
    }

    function post(DataTypes.PostData calldata _postData)
        external
        override
        onlyGelatoRelay
    {
        require(
            _postData.profileId == koruDaoProfileId,
            "KoruDao: Only post for KoruDao"
        );
        address user = _msgSender();

        IKoruDaoRestriction restriction = _getRestriction(Action.POST);

        uint256 token = restriction.checkAndUpdateRestriction(
            user,
            uint256(Action.POST)
        );

        uint256 pubId = lensHub.post(_postData);

        emit LogPost(user, token, pubId, block.timestamp);
    }

    function follow(uint256 _profileId, bytes calldata _followData)
        external
        override
        onlyGelatoRelay
    {
        address user = _msgSender();

        IKoruDaoRestriction restriction = _getRestriction(Action.FOLLOW);

        uint256 token = restriction.checkAndUpdateRestriction(
            user,
            uint256(Action.FOLLOW)
        );

        uint256[] memory profileIds = new uint256[](1);
        bytes[] memory followDatas = new bytes[](1);

        profileIds[0] = _profileId;
        followDatas[0] = _followData;

        uint256[] memory followTokenIds = lensHub.follow(
            profileIds,
            followDatas
        );

        emit LogFollow(user, token, followTokenIds, block.timestamp);
    }

    function mirror(DataTypes.MirrorData calldata _mirrorData)
        external
        override
        onlyGelatoRelay
    {
        require(
            _mirrorData.profileId == koruDaoProfileId,
            "KoruDao: Only mirror for KoruDao"
        );
        address user = _msgSender();

        IKoruDaoRestriction restriction = _getRestriction(Action.MIRROR);

        uint256 token = restriction.checkAndUpdateRestriction(
            user,
            uint256(Action.MIRROR)
        );

        uint256 pubId = lensHub.mirror(_mirrorData);

        emit LogMirror(user, token, pubId, block.timestamp);
    }

    function setActionRestriction(Action _action, address _restriction)
        external
        onlyProxyAdmin
    {
        actionRestriction[_action] = _restriction;
    }

    function setDefaultProfile(uint256 _profileId) external onlyProxyAdmin {
        lensHub.setDefaultProfile(_profileId);
    }

    function _getRestriction(Action _action)
        private
        view
        returns (IKoruDaoRestriction restriction)
    {
        restriction = IKoruDaoRestriction(actionRestriction[_action]);

        require(
            address(restriction) != address(0),
            "KoruDao: Action not active"
        );
    }
}
