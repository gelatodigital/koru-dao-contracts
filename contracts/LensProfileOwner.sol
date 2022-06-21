// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {ILensHub} from "./interfaces/ILensHub.sol";

abstract contract LensProfileOwner {
    ILensHub public immutable lensHub;

    modifier onlyLensProfileOwner(address sender) {
        require(
            _hasLensProfile(sender),
            "LensDaoNFT: Only lens profile holder"
        );
        _;
    }

    constructor(ILensHub _lensHub) {
        lensHub = _lensHub;
    }

    function _hasLensProfile(address _wallet) private view returns (bool) {
        return lensHub.defaultProfile(_wallet) != 0;
    }
}
