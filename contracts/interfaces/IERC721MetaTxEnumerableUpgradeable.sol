// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IERC721MetaTxEnumerableUpgradeable is IERC721EnumerableUpgradeable {
    function gelatoRelay() external view returns (address);
}
