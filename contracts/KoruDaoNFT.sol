// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {
    ERC721MetaTxEnumerableUpgradeable
} from "./ERC721MetaTxEnumerableUpgradeable.sol";
import {MintRestrictions} from "./MintRestrictions.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

contract KoruDaoNFT is
    MintRestrictions,
    ERC721MetaTxEnumerableUpgradeable,
    Proxied
{
    using Strings for uint256;

    uint256 public immutable maxSupply;
    string public baseUri;
    bool public paused;
    mapping(uint256 => bool) public lensProfileMinted;

    modifier notPaused() {
        require(!paused, "KoruDaoNFT: Paused");
        _;
    }

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
        ERC721MetaTxEnumerableUpgradeable(_gelatoRelay)
    {
        maxSupply = _maxSupply;
    }

    function initialize(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseUri,
        bool _paused
    ) external initializer {
        __ERC721MetaTxEnumerableUpgradeable_init(_name, _symbol);
        baseUri = _baseUri;
        paused = _paused;
    }

    function mint()
        external
        notPaused
        onlyGelatoRelay
        onlyEligible(_msgSender())
    {
        address user = _msgSender();

        if (restricted) {
            uint256 profileId = lensHub.defaultProfile(user);
            require(
                !lensProfileMinted[profileId],
                "MintRestrictions: Already minted with lens profile"
            );

            lensProfileMinted[profileId] = true;
        }
        _mint(user);
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
