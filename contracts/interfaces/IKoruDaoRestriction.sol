// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {DataTypes} from "../libraries/LensDataTypes.sol";

interface IKoruDaoRestriction {
    function checkAndUpdateRestriction(uint256 _token, uint256 _action)
        external;

    function checkRestriction(uint256 _token, uint256 _action) external view;
}
