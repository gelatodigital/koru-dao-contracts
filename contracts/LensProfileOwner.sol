// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {ILensHub} from "./interfaces/ILensHub.sol";

abstract contract LensProfileOwner {
    ILensHub public immutable lensHub;

    modifier onlyLensProfileOwner(address sender) {
        require(hasLensProfile(sender), "KoruDaoNFT: Only lens profile holder");
        _;
    }

    constructor(ILensHub _lensHub) {
        lensHub = _lensHub;
    }

    function hasLensProfile(address _wallet) public view returns (bool) {
        return lensHub.balanceOf(_wallet) > 0;
    }
}
