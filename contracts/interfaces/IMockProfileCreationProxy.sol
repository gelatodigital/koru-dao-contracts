// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {DataTypes} from "../libraries/LensDataTypes.sol";

interface IMockProfileCreationProxy {
    function proxyCreateProfile(DataTypes.CreateProfileData memory vars)
        external;
}
