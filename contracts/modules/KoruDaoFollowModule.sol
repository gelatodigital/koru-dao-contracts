// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {KoruDaoModuleBase} from "./KoruDaoModuleBase.sol";
import {DataTypes} from "../libraries/LensDataTypes.sol";

//solhint-disable not-rely-on-time
//solhint-disable no-empty-blocks
contract KoruDaoFollowModule is KoruDaoModuleBase {
    uint256 public immutable followInterval;

    event LogFollow(
        address indexed user,
        uint256 indexed token,
        uint256[] indexed followerTokenIds,
        uint256 time
    );

    constructor(
        address _koruDao,
        address _koruDaoNft,
        address _lensHub,
        uint256 _followInterval
    ) KoruDaoModuleBase(_koruDao, _koruDaoNft, _lensHub) {
        followInterval = _followInterval;
    }

    function performAction(address _user, bytes calldata _actionData)
        external
        override
        onlyKoruDao
    {
        uint256 token = checkFollowRestrictions(_user);

        (uint256 profileId, bytes memory followData) = decodeActionData(
            _actionData
        );

        uint256[] memory profileIds = new uint256[](1);
        bytes[] memory followDatas = new bytes[](1);

        profileIds[0] = profileId;
        followDatas[0] = followData;

        uint256[] memory followerTokenIds = lensHub.follow(
            profileIds,
            followDatas
        );

        emit LogFollow(_user, token, followerTokenIds, block.timestamp);
    }

    function checkFollowRestrictions(address _user)
        public
        view
        returns (uint256 token)
    {
        require(
            koruDaoNft.balanceOf(_user) > 0,
            "KoruDaoPostModule: No KoruDaoNft"
        );

        token = koruDaoNft.tokenOfOwnerByIndex(_user, 0);

        require(
            (block.timestamp - lastFollow[token] >= followInterval),
            "KoruDaoPostModule: Follow too frequent"
        );
    }

    function encodeActionData(uint256 _profileId, bytes calldata _followData)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(_profileId, _followData);
    }

    function decodeActionData(bytes calldata _actionData)
        public
        pure
        returns (uint256 profileId, bytes memory followData)
    {
        (profileId, followData) = abi.decode(_actionData, (uint256, bytes));
    }
}
