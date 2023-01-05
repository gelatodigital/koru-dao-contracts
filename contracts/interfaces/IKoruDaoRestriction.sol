// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {DataTypes} from "../libraries/LensDataTypes.sol";

interface IKoruDaoRestriction {
    function checkAndUpdateRestriction(address _user, uint256 _action)
        external
        returns (uint256 token);

    function checkRestriction(uint256 _token, uint256 _action) external view;

    function getKoruDaoNftTokenId(address _user)
        external
        view
        returns (uint256 token);
}
