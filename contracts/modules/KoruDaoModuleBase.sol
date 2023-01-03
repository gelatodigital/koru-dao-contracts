// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {KoruDaoStorage} from "../KoruDaoStorage.sol";
import {IKoruDaoModule} from "../interfaces/IKoruDaoModule.sol";

//solhint-disable no-empty-blocks
abstract contract KoruDaoModuleBase is KoruDaoStorage, IKoruDaoModule {
    modifier onlyKoruDao() {
        require(msg.sender == koruDao, "KoruDaoModuleBase: Only Koru Dao");
        _;
    }

    constructor(
        address _koruDao,
        address _koruDaoNft,
        address _lensHub
    ) KoruDaoStorage(_koruDao, _koruDaoNft, _lensHub) {}

    function performAction(address _user, bytes calldata _actionData)
        external
        virtual
        override
        onlyKoruDao
    {}
}
