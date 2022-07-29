// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IGelatoMetaBox {
    struct MetaTxRequest {
        uint256 chainId;
        address target;
        bytes data;
        address feeToken;
        uint256 paymentType;
        uint256 maxFee;
        uint256 gas;
        address user;
        address sponsor; // could be same as user
        uint256 sponsorChainId;
        uint256 nonce;
        uint256 deadline;
    }

    function metaTxRequestGasTankFee(
        MetaTxRequest calldata _req,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external;

    function nonce(address _user) external view returns (uint256);
}
