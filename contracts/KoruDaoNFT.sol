// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {ERC721MetaTx} from "./vendor/oz/ERC721MetaTx.sol";
import {ERC721MetaTxEnumerable} from "./vendor/oz/ERC721MetaTxEnumerable.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {Restrictions} from "./Restrictions.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

contract KoruDaoNFT is Restrictions, ERC721MetaTxEnumerable, Proxied {
    uint256 public immutable maxSupply;
    string public baseUri;

    //solhint-disable no-empty-blocks
    constructor(
        bool _restricted,
        uint256 _maxSupply,
        ILensHub _lensHub,
        address _gelatoRelay
    )
        Restrictions(_restricted, _lensHub, _gelatoRelay)
        ERC721MetaTx("Koru Dao NFT", "KORUDAO", _gelatoRelay)
    {
        maxSupply = _maxSupply;
    }

    function mint()
        external
        onlyGelatoRelay(msg.sender)
        onlyLensProfileOwner(_msgSender())
    {
        uint256 supplyTotal = totalSupply();

        if (maxSupply > 0)
            require(supplyTotal < maxSupply, "KoruDaoNFT: Max Supply");

        _safeMint(_msgSender(), supplyTotal + 1);
    }

    function setBaseUri(string memory _baseUri) external onlyProxyAdmin {
        baseUri = _baseUri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (to != address(0)) _onlyOnePerAccount(to);

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function _onlyOnePerAccount(address _account) private view {
        require(balanceOf(_account) == 0, "KoruDaoNFT: One per account");
    }
}
