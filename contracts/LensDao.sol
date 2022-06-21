// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {LensProfileOwner} from "./LensProfileOwner.sol";
import {LensDataTypes} from "./libraries/LensDataTypes.sol";
import {IERC721MetaTxEnumerable} from "./vendor/oz/IERC721MetaTxEnumerable.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

contract LensDao is LensProfileOwner, ERC2771Context, Proxied {
    IERC721MetaTxEnumerable public immutable lensDaoNft;
    uint256 public immutable postInterval;
    uint256 public postPrice;
    mapping(uint256 => uint256) public lastPost;

    constructor(
        IERC721MetaTxEnumerable _lensDaoNft,
        ILensHub _lensHub,
        address _gelatoMetaBox
    ) LensProfileOwner(_lensHub) ERC2771Context(_gelatoMetaBox) {
        lensDaoNft = _lensDaoNft;
    }

    function post(
        uint256 _lensDaoTokenId,
        LensDataTypes.CreateProfileData calldata vars
    ) external onlyLensProfileOwner {
        require(
            lensDaoNft.ownerOf(tokenId) == _msgSender(),
            "LensDao: Not owner"
        );
        require(
            block.timestamp - lastPost[_lensDaoTokenId] >= postInterval,
            "LensDao: Post too frequent"
        );

        lensHub.post(vars);
        lastPost[_lensDaoTokenId] = block.timestamp;
    }
}
