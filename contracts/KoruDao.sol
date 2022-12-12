// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {
    ERC721Holder
} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {DataTypes} from "./libraries/LensDataTypes.sol";
import {
    IERC721MetaTxEnumerableUpgradeable
} from "./interfaces/IERC721MetaTxEnumerableUpgradeable.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

//solhint-disable not-rely-on-time
contract KoruDao is ERC721Holder, ERC2771Context, Proxied {
    uint256 public immutable postInterval;
    IERC721MetaTxEnumerableUpgradeable public immutable koruDaoNft;
    ILensHub public immutable lensHub;
    mapping(uint256 => uint256) public lastPost;

    event LogPost(
        address indexed user,
        uint256 indexed token,
        uint256 indexed pubId,
        uint256 time
    );

    modifier onlyGelatoRelay() {
        require(isTrustedForwarder(msg.sender), "KoruDao: Only GelatoRelay");
        _;
    }

    constructor(
        uint256 _postInterval,
        address _gelatoRelay,
        IERC721MetaTxEnumerableUpgradeable _koruDaoNft,
        ILensHub _lensHub
    ) ERC2771Context(_gelatoRelay) {
        postInterval = _postInterval;
        koruDaoNft = _koruDaoNft;
        lensHub = _lensHub;
    }

    function post(DataTypes.PostData calldata _postVars)
        external
        onlyGelatoRelay
    {
        address msgSender = _msgSender();

        require(koruDaoNft.balanceOf(msgSender) > 0, "KoruDao: No KoruDaoNft");

        uint256 token = koruDaoNft.tokenOfOwnerByIndex(msgSender, 0);

        require(canPost(token), "KoruDao: Post too frequent");

        uint256 pubId = lensHub.post(_postVars);

        lastPost[token] = block.timestamp;

        emit LogPost(msgSender, token, pubId, block.timestamp);
    }

    function setDefaultProfile(uint256 _profileId) external onlyProxyAdmin {
        lensHub.setDefaultProfile(_profileId);
    }

    function canPost(uint256 _token) public view returns (bool) {
        if (block.timestamp - lastPost[_token] >= postInterval) return true;

        return false;
    }
}
