// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {LensProfileOwner} from "./LensProfileOwner.sol";
import {DataTypes} from "./libraries/LensDataTypes.sol";
import {IERC721MetaTxEnumerable} from "./vendor/oz/IERC721MetaTxEnumerable.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

contract LensDao is LensProfileOwner, ERC2771Context, Proxied {
    IERC721MetaTxEnumerable public immutable lensDaoNft;
    uint256 public immutable postInterval;
    mapping(address => uint256) public lastPost;

    constructor(
        IERC721MetaTxEnumerable _lensDaoNft,
        uint256 _postInterval,
        ILensHub _lensHub,
        address _gelatoMetaBox
    ) LensProfileOwner(_lensHub) ERC2771Context(_gelatoMetaBox) {
        lensDaoNft = _lensDaoNft;
        postInterval = _postInterval;
    }

    //solhint-disable not-rely-on-time
    function post(DataTypes.PostData calldata _vars)
        external
        onlyLensProfileOwner(_msgSender())
    {
        address msgSender = _msgSender();

        require(lensDaoNft.balanceOf(msgSender) > 0, "LensDao: No LensDaoNFT");
        require(
            block.timestamp - lastPost[msgSender] >= postInterval,
            "LensDao: Post too frequent"
        );

        lensHub.post(_vars);
        lastPost[msgSender] = block.timestamp;
    }
}
