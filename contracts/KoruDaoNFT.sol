// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721MetaTx} from "./vendor/oz/ERC721MetaTx.sol";
import {ERC721MetaTxEnumerable} from "./vendor/oz/ERC721MetaTxEnumerable.sol";
import {MintRestrictions} from "./MintRestrictions.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

contract KoruDaoNFT is MintRestrictions, ERC721MetaTxEnumerable, Proxied {
    using Strings for uint256;

    uint256 public immutable maxSupply;
    string public baseUri;
    bool public paused;

    modifier notPaused() {
        require(!paused, "KoruDaoNFT: Paused");
        _;
    }

    modifier onlyGelatoRelay() {
        require(isTrustedForwarder(msg.sender), "KoruDao: Only GelatoRelay");
        _;
    }

    //solhint-disable no-empty-blocks
    constructor(
        bool _restricted,
        uint256 _maxSupply,
        uint256 _koruDaoProfileId,
        uint256 _minPubCount,
        uint256 _minFollowers,
        address _gelatoRelay,
        ILensHub _lensHub
    )
        MintRestrictions(
            _restricted,
            _koruDaoProfileId,
            _minPubCount,
            _minFollowers,
            _lensHub
        )
        ERC721MetaTx("Koru Dao NFT", "KORUDAO", _gelatoRelay)
    {
        maxSupply = _maxSupply;
    }

    function mint()
        external
        notPaused
        onlyGelatoRelay
        onlyEligible(_msgSender())
    {
        _mint(_msgSender());
    }

    function ownerMint(address[] calldata _users) external onlyProxyAdmin {
        uint256 length = _users.length;
        for (uint256 i; i < length; i++) {
            _mint(_users[i]);
        }
    }

    function setBaseUri(string memory _baseUri) external onlyProxyAdmin {
        baseUri = _baseUri;
    }

    function setPaused(bool _paused) external onlyProxyAdmin {
        paused = _paused;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        uint256 uriId = !restricted && tokenId > maxSupply
            ? (tokenId % maxSupply) + 1
            : tokenId;

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, uriId.toString(), ".json"))
                : "";
    }

    function name() public pure override returns (string memory) {
        return "Koru Dao";
    }

    function symbol() public pure override returns (string memory) {
        return "KORUDAO";
    }

    function _mint(address _user) internal {
        uint256 supplyTotal = totalSupply();

        if (restricted)
            require(supplyTotal < maxSupply, "KoruDaoNFT: Max Supply");

        _safeMint(_user, supplyTotal + 1);
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
