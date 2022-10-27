// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {
    ERC721Holder
} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {Restrictions} from "./Restrictions.sol";
import {DataTypes} from "./libraries/LensDataTypes.sol";
import {IERC721MetaTxEnumerable} from "./vendor/oz/IERC721MetaTxEnumerable.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

contract KoruDao is Restrictions, ERC721Holder, ERC2771Context, Proxied {
    IERC721MetaTxEnumerable public immutable koruDaoNft;
    uint256 public immutable postInterval;
    mapping(address => uint256) public lastPost;

    constructor(
        bool _restricted,
        uint256 _postInterval,
        address _gelatoRelay,
        IERC721MetaTxEnumerable _koruDaoNft,
        ILensHub _lensHub
    )
        Restrictions(_restricted, _gelatoRelay, _lensHub)
        ERC2771Context(_gelatoRelay)
    {
        koruDaoNft = _koruDaoNft;
        postInterval = _postInterval;
    }

    //solhint-disable not-rely-on-time
    function post(DataTypes.PostData calldata _vars)
        external
        onlyGelatoRelay
        onlyLensProfileOwner(_msgSender())
    {
        address msgSender = _msgSender();

        require(koruDaoNft.balanceOf(msgSender) > 0, "KoruDao: No KoruDaoNft");
        require(canPost(msgSender), "KoruDao: Post too frequent");

        lensHub.post(_vars);
        lastPost[msgSender] = block.timestamp;
    }

    function setDefaultProfile(uint256 _profileId) external onlyProxyAdmin {
        lensHub.setDefaultProfile(_profileId);
    }

    function canPost(address _user) public view returns (bool) {
        if (block.timestamp - lastPost[_user] >= postInterval) return true;

        return false;
    }
}
