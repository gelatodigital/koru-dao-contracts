// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IKoruDaoModule {
    function performAction(address _user, bytes calldata _actionData) external;
}
