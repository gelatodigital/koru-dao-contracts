// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {
    IERC721MetaTxEnumerableUpgradeable
} from "./interfaces/IERC721MetaTxEnumerableUpgradeable.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

// solhint-disable max-states-count
abstract contract KoruDaoStorage {
    address public immutable koruDao;
    IERC721MetaTxEnumerableUpgradeable public immutable koruDaoNft;
    ILensHub public immutable lensHub;

    EnumerableSet.AddressSet internal _whitelistedModules;

    mapping(uint256 => uint256) public lastPost; ///@dev {KoruDaoPostModule.sol}
    mapping(uint256 => uint256) public lastMirror; ///@dev {KoruDaoMirrorModule.sol}
    mapping(uint256 => uint256) public lastFollow; ///@dev {KoruDaoFollowModule.sol}

    constructor(
        address _koruDao,
        address _koruDaoNft,
        address _lensHub
    ) {
        koruDao = _koruDao;
        koruDaoNft = IERC721MetaTxEnumerableUpgradeable(_koruDaoNft);
        lensHub = ILensHub(_lensHub);
    }
}
