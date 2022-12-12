// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./vendor/opensea/DefaultOperatorFiltererUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

/**
 * @dev ERC721MetaTxEnumerableUpgradeable is an extension of
 * {ERC721EnumerableUpgradeable} implementation with
 *
 * 1. ERC2771Context
 * 2. OpenSea's DefaultOperatorFilter (https://github.com/ProjectOpenSea/operator-filter-registry)
 *
 */
abstract contract ERC721MetaTxEnumerableUpgradeable is
    ERC721EnumerableUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    address public immutable gelatoRelay;

    modifier onlyGelatoRelay() {
        require(_isGelatoRelay(msg.sender), "Only GelatoRelay");
        _;
    }

    constructor(address _gelatoRelay) {
        gelatoRelay = _gelatoRelay;
    }

    function __ERC721MetaTxEnumerableUpgradeable_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __ERC721Enumerable_init();
        __ERC721_init(name_, symbol_);
        __DefaultOperatorFilterer_init();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _msgSender() internal view override returns (address sender) {
        if (_isGelatoRelay(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view override returns (bytes calldata) {
        if (_isGelatoRelay(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function _isGelatoRelay(address forwarder) private view returns (bool) {
        return forwarder == gelatoRelay;
    }
}
