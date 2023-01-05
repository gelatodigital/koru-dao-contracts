// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    IERC721Enumerable
} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

//solhint-disable code-complexity
abstract contract MintRestrictions {
    bool public immutable restricted;
    uint256 public immutable koruDaoProfileId;
    uint256 public immutable minPubCount;
    uint256 public immutable minFollowers;
    ILensHub public immutable lensHub;

    modifier onlyEligible(address _wallet) {
        if (restricted) {
            (bool eligible, ) = isEligible(_wallet);
            require(
                eligible,
                "MintRestrictions: Wallet does not meet criteria"
            );
        }

        _;
    }

    constructor(
        bool _restricted,
        uint256 _koruDaoProfileId,
        uint256 _minPubCount,
        uint256 _minFollowers,
        ILensHub _lensHub
    ) {
        restricted = _restricted;
        koruDaoProfileId = _koruDaoProfileId;
        minPubCount = _minPubCount;
        minFollowers = _minFollowers;
        lensHub = _lensHub;
    }

    function isEligible(address _wallet)
        public
        view
        returns (bool, bool[] memory)
    {
        if (!restricted) return (true, new bool[](4));

        uint256 profileId = lensHub.defaultProfile(_wallet);
        require(
            profileId != 0,
            "MintRestrictions: Wallet does not have default profile"
        );

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

    function _hasLensProfile(address _wallet) private view returns (bool) {
        return lensHub.balanceOf(_wallet) > 0;
    }

    function _isFollowingKoruDao(address _wallet) private view returns (bool) {
        address followNFT = lensHub.getFollowNFT(koruDaoProfileId);
        if (followNFT == address(0)) return false;

        return IERC721Enumerable(followNFT).balanceOf(_wallet) > 0;
    }

    function _hasMinPublish(uint256 _profileId) private view returns (bool) {
        uint256 pubCount = lensHub.getPubCount(_profileId);

        return pubCount >= minPubCount;
    }

    function _hasMinFollower(uint256 _profileId) private view returns (bool) {
        address followNFT = lensHub.getFollowNFT(_profileId);

        if (followNFT == address(0)) return false;

        uint256 followers = IERC721Enumerable(followNFT).totalSupply();
        return followers >= minFollowers;
    }
}
