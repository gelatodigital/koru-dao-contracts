// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {DataTypes} from "../libraries/LensDataTypes.sol";

interface IKoruDaoRestriction {
    function postAction(uint256 _token, uint256 _action) external;

    function preActionCheck(uint256 _token, uint256 _action) external view;
}
