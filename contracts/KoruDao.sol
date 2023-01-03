// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {
    ERC721Holder
} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {KoruDaoStorage} from "./KoruDaoStorage.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {GelatoBytes} from "./vendor/gelato/GelatoBytes.sol";
import {IKoruDaoModule} from "./interfaces/IKoruDaoModule.sol";

//solhint-disable no-empty-blocks
contract KoruDao is ERC721Holder, ERC2771Context, Proxied, KoruDaoStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier onlyGelatoRelay() {
        require(isTrustedForwarder(msg.sender), "KoruDao: Only GelatoRelay");
        _;
    }

    modifier onlyWhitelistedModule(address _module) {
        require(
            _whitelistedModules.contains(_module),
            "KoruDao: Only whitelisted modules"
        );
        _;
    }

    constructor(
        address _gelatoRelay,
        address _koruDao,
        address _koruDaoNft,
        address _lensHub
    )
        ERC2771Context(_gelatoRelay)
        KoruDaoStorage(_koruDao, _koruDaoNft, _lensHub)
    {}

    function doAction(address _koruDaoModule, bytes calldata _actionData)
        external
        onlyGelatoRelay
        onlyWhitelistedModule(_koruDaoModule)
    {
        address user = _msgSender();

        (bool success, bytes memory returnData) = _koruDaoModule.delegatecall(
            abi.encodeCall(IKoruDaoModule.performAction, (user, _actionData))
        );

        if (!success) GelatoBytes.revertWithError(returnData, "KoruDao: ");
    }

    function setDefaultProfile(uint256 _profileId) external onlyProxyAdmin {
        lensHub.setDefaultProfile(_profileId);
    }

    function getWhitelistedModules() external view returns (address[] memory) {
        return _whitelistedModules.values();
    }
}
