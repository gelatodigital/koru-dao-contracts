// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {DataTypes} from "../libraries/LensDataTypes.sol";

interface IKoruDao {
    function post(DataTypes.PostData calldata _vars) external;
}
