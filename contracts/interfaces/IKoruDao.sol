// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {DataTypes} from "../libraries/LensDataTypes.sol";

interface IKoruDao {
    enum Action {
        POST,
        FOLLOW,
        MIRROR
    }

    event LogPost(
        address indexed user,
        uint256 indexed token,
        uint256 indexed pubId,
        uint256 time
    );

    event LogFollow(
        address indexed user,
        uint256 indexed token,
        uint256[] indexed followTokenIds,
        uint256 time
    );

    event LogMirror(
        address indexed user,
        uint256 indexed token,
        uint256 indexed pubId,
        uint256 time
    );

    function post(DataTypes.PostData calldata _postData) external;

    function follow(uint256 _profileId, bytes calldata _followData) external;

    function mirror(DataTypes.MirrorData calldata _mirrorData) external;

    function getKoruDaoNftTokenId(address _user)
        external
        view
        returns (uint256 token);
}
