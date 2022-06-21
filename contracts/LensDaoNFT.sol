// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {ERC721MetaTxEnumerable} from "./vendor/oz/ERC721MetaTxEnumerable.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {LensProfileOwner} from "./LensProfileOwner.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

contract LensDaoNFT is LensProfileOwner, ERC721MetaTxEnumerable, Proxied {
    uint256 public immutable maxSupply;
    string public baseUri;

    //solhint-disable no-empty-blocks
    constructor(ILensHub _lensHub, address _gelatoMetaBox)
        LensProfileOwner(_lensHub)
        ERC721MetaTx("Lens Dao Nft", "LENSDAO", _gelatoMetaBox)
    {}

    function mint() external onlyLensProfileOwner {
        uint256 supplyTotal = totalSupply();

        require(supplyTotal < maxSupply, "LensDaoNFT: Max Supply");
        require(balanceOf(_msgSender()) == 0, "LensDaoNFT: One per wallet");

        _safeMint(_msgSender(), supplyTotal + 1);
    }

    function setBaseUri(string memory _baseUri) external onlyProxyAdmin {
        baseUri = _baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}
