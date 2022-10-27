// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {ILensHub} from "./interfaces/ILensHub.sol";

abstract contract Restrictions {
    bool public immutable restricted;
    address public immutable gelatoRelay;
    ILensHub public immutable lensHub;

    modifier onlyLensProfileOwner(address sender) {
        if (restricted)
            require(
                _hasLensProfile(sender),
                "Restrictions: Only lens profile holder"
            );
        _;
    }

    modifier onlyGelatoRelay() {
        require(msg.sender == gelatoRelay, "Restrictions: Only Gelato relay");
        _;
    }

    constructor(
        bool _restricted,
        address _gelatoRelay,
        ILensHub _lensHub
    ) {
        restricted = _restricted;
        lensHub = _lensHub;
        gelatoRelay = _gelatoRelay;
    }

    function _hasLensProfile(address _wallet) internal view returns (bool) {
        return lensHub.balanceOf(_wallet) > 0;
    }
}
