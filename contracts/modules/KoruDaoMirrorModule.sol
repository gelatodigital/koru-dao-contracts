// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {KoruDaoModuleBase} from "./KoruDaoModuleBase.sol";
import {DataTypes} from "../libraries/LensDataTypes.sol";

//solhint-disable not-rely-on-time
contract KoruDaoMirrorModule is KoruDaoModuleBase {
    uint256 public immutable mirrorInterval;

    event LogMirror(
        address indexed user,
        uint256 indexed token,
        uint256 indexed pubId,
        uint256 time
    );

    constructor(
        address _koruDao,
        address _koruDaoNft,
        address _lensHub,
        uint256 _mirrorInterval
    ) KoruDaoModuleBase(_koruDao, _koruDaoNft, _lensHub) {
        mirrorInterval = _mirrorInterval;
    }

    function performAction(address _user, bytes calldata _actionData)
        external
        override
        onlyKoruDao
    {
        uint256 token = checkMirrorRestrictions(_user);

        DataTypes.MirrorData memory mirrorData = decodeActionData(_actionData);

        uint256 pubId = lensHub.mirror(mirrorData);

        lastMirror[token] = block.timestamp;

        emit LogMirror(_user, token, pubId, block.timestamp);
    }

    function checkMirrorRestrictions(address _user)
        public
        view
        returns (uint256 token)
    {
        require(
            koruDaoNft.balanceOf(_user) > 0,
            "KoruDaoPostModule: No KoruDaoNft"
        );

        token = koruDaoNft.tokenOfOwnerByIndex(_user, 0);

        require(
            (block.timestamp - lastMirror[token] >= mirrorInterval),
            "KoruDaoPostModule: Mirror too frequent"
        );
    }

    function encodeActionData(DataTypes.MirrorData memory _mirrorData)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(_mirrorData);
    }

    function decodeActionData(bytes calldata _actionData)
        public
        pure
        returns (DataTypes.MirrorData memory mirrorData)
    {
        mirrorData = abi.decode(_actionData, (DataTypes.MirrorData));
    }
}
