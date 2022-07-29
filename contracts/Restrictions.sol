// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {ILensHub} from "./interfaces/ILensHub.sol";

abstract contract Restrictions {
    bool public immutable restricted;
    ILensHub public immutable lensHub;
    address public immutable gelatoRelay;

    modifier onlyLensProfileOwner(address sender) {
        if (restricted)
            require(
                hasLensProfile(sender),
                "Restrictions: Only lens profile holder"
            );
        _;
    }

    modifier onlyGelatoRelay(address sender) {
        require(sender == gelatoRelay, "Restrictions: Only Gelato relay");
        _;
    }

    constructor(
        bool _restricted,
        ILensHub _lensHub,
        address _gelatoRelay
    ) {
        restricted = _restricted;
        lensHub = _lensHub;
        gelatoRelay = _gelatoRelay;
    }

    function hasLensProfile(address _wallet) public view returns (bool) {
        return lensHub.balanceOf(_wallet) > 0;
    }
}
