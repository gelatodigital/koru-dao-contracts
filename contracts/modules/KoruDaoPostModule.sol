// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {KoruDaoModuleBase} from "./KoruDaoModuleBase.sol";
import {DataTypes} from "../libraries/LensDataTypes.sol";

//solhint-disable not-rely-on-time
contract KoruDaoPostModule is KoruDaoModuleBase {
    uint256 public immutable postInterval;

    event LogPost(
        address indexed user,
        uint256 indexed token,
        uint256 indexed pubId,
        uint256 time
    );

    constructor(
        address _koruDao,
        address _koruDaoNft,
        address _lensHub,
        uint256 _postInterval
    ) KoruDaoModuleBase(_koruDao, _koruDaoNft, _lensHub) {
        postInterval = _postInterval;
    }

    function performAction(address _user, bytes calldata _actionData)
        external
        override
        onlyKoruDao
    {
        uint256 token = checkPostRestrictions(_user);

        DataTypes.PostData memory postData = decodeActionData(_actionData);

        uint256 pubId = lensHub.post(postData);

        lastPost[token] = block.timestamp;

        emit LogPost(_user, token, pubId, block.timestamp);
    }

    function checkPostRestrictions(address _user)
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
            (block.timestamp - lastPost[token] >= postInterval),
            "KoruDaoPostModule: Post too frequent"
        );
    }

    function encodeActionData(DataTypes.PostData memory _postData)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(_postData);
    }

    function decodeActionData(bytes calldata _actionData)
        public
        pure
        returns (DataTypes.PostData memory postData)
    {
        postData = abi.decode(_actionData, (DataTypes.PostData));
    }
}
