// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {IKoruDao} from "./interfaces/IKoruDao.sol";
import {IKoruDaoRestriction} from "./interfaces/IKoruDaoRestriction.sol";

//solhint-disable not-rely-on-time
contract TimeRestrictionForPosting is IKoruDaoRestriction {
    uint256 public immutable actionInterval;
    address public immutable koruDao;
    mapping(bytes32 => uint256) public lastActionTime;

    modifier onlyKoruDao() {
        require(
            msg.sender == koruDao,
            "TimeRestrictionForPosting: Only KoruDao"
        );
        _;
    }

    constructor(uint256 _actionInterval, address _koruDao) {
        actionInterval = _actionInterval;
        koruDao = _koruDao;
    }

    function checkAndUpdateRestriction(uint256 _token, uint256 _action)
        external
        override
        onlyKoruDao
    {
        checkRestriction(_token, _action);

        bytes32 tokenActionHash = keccak256(abi.encode(_token, _action));

        lastActionTime[tokenActionHash] = block.timestamp;
    }

    function lastPost(uint256 _token) external view returns (uint256) {
        bytes32 tokenActionHash = keccak256(
            abi.encode(_token, uint256(IKoruDao.Action.POST))
        );

        return lastActionTime[tokenActionHash];
    }

    function checkRestriction(uint256 _token, uint256 _action)
        public
        view
        override
    {
        bytes32 tokenActionHash = keccak256(abi.encode(_token, _action));

        require(
            (block.timestamp - lastActionTime[tokenActionHash] >=
                actionInterval),
            "TimeRestrictionForPosting: Too frequent"
        );
    }

    /// @dev can be added as desired
    // function lastFollow(uint256 _token) external view returns (uint256) {
    //     bytes32 tokenActionHash = keccak256(
    //         abi.encode(_token, uint256(IKoruDao.Action.FOLLOW))
    //     );

    //     return lastActionTime[tokenActionHash];
    // }

    // function lastMirror(uint256 _token) external view returns (uint256) {
    //     bytes32 tokenActionHash = keccak256(
    //         abi.encode(_token, uint256(IKoruDao.Action.MIRROR))
    //     );

    //     return lastActionTime[tokenActionHash];
    // }
}
