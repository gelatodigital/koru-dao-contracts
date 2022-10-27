// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {Restrictions} from "./Restrictions.sol";
import {
    IERC721Enumerable
} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

abstract contract MintRestrictions is Restrictions {
    uint256 public immutable koruDaoProfileId;
    uint256 public immutable minPubCount;
    uint256 public immutable minFollowers;

    modifier onlyEligible(address sender) {
        if (restricted) {
            (bool eligible, ) = isEligible(sender);
            require(
                eligible,
                "MintRestrictions: Sender does not meet criteria"
            );
        }

        _;
    }

    constructor(
        bool _restricted,
        uint256 _koruDaoProfileId,
        uint256 _minPubCount,
        uint256 _minFollowers,
        address _gelatoRelay,
        ILensHub _lensHub
    ) Restrictions(_restricted, _gelatoRelay, _lensHub) {
        koruDaoProfileId = _koruDaoProfileId;
        minPubCount = _minPubCount;
        minFollowers = _minFollowers;
    }

    function isEligible(address _wallet)
        public
        view
        returns (bool, bool[] memory)
    {
        uint256 profileId = lensHub.defaultProfile(_wallet);

        bool eligible = true;
        bool[] memory unmetCriterias = new bool[](4);

        if (!_hasLensProfile(_wallet)) {
            unmetCriterias[0] = true;
            eligible = false;
        }
        if (!_isFollowingKoruDao(_wallet)) {
            unmetCriterias[1] = true;
            eligible = false;
        }
        if (!_hasMinPublish(profileId)) {
            unmetCriterias[2] = true;
            eligible = false;
        }
        if (!_hasMinFollower(profileId)) {
            unmetCriterias[3] = true;
            eligible = false;
        }

        return (eligible, unmetCriterias);
    }

    function _isFollowingKoruDao(address _wallet) private view returns (bool) {
        IERC721Enumerable followNFT = IERC721Enumerable(
            lensHub.getFollowNFT(koruDaoProfileId)
        );

        return followNFT.balanceOf(_wallet) > 0;
    }

    function _hasMinPublish(uint256 _profileId) private view returns (bool) {
        uint256 pubCount = lensHub.getPubCount(_profileId);

        return pubCount >= minPubCount;
    }

    function _hasMinFollower(uint256 _profileId) private view returns (bool) {
        IERC721Enumerable followNFT = IERC721Enumerable(
            lensHub.getFollowNFT(_profileId)
        );

        uint256 followers = followNFT.totalSupply();
        return followers >= minFollowers;
    }
}
