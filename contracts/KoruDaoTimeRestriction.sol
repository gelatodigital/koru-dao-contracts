// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {IKoruDao} from "./interfaces/IKoruDao.sol";
import {IKoruDaoRestriction} from "./interfaces/IKoruDaoRestriction.sol";

//solhint-disable not-rely-on-time
contract KoruDaoTimeRestriction is IKoruDaoRestriction {
    uint256 public immutable actionInterval;
    address public immutable koruDao;
    mapping(bytes32 => uint256) public lastActionTime;

    modifier onlyKoruDao() {
        require(msg.sender == koruDao, "KoruDaoTimeRestriction: Only KoruDao");
        _;
    }

    constructor(uint256 _actionInterval, address _koruDao) {
        actionInterval = _actionInterval;
        koruDao = _koruDao;
    }

    function postAction(uint256 _token, uint256 _action)
        external
        override
        onlyKoruDao
    {
        bytes32 tokenActionHash = keccak256(abi.encode(_token, _action));

        lastActionTime[tokenActionHash] = block.timestamp;
    }

    function preActionCheck(uint256 _token, uint256 _action)
        external
        view
        override
    {
        bytes32 tokenActionHash = keccak256(abi.encode(_token, _action));

        require(
            (block.timestamp - lastActionTime[tokenActionHash] >=
                actionInterval),
            "KoruDaoTimeRestriction: Too frequent"
        );
    }

    function lastPost(uint256 _token) external view returns (uint256) {
        bytes32 tokenActionHash = keccak256(
            abi.encode(_token, uint256(IKoruDao.Action.POST))
        );

        return lastActionTime[tokenActionHash];
    }

    function lastFollow(uint256 _token) external view returns (uint256) {
        bytes32 tokenActionHash = keccak256(
            abi.encode(_token, uint256(IKoruDao.Action.FOLLOW))
        );

        return lastActionTime[tokenActionHash];
    }

    function lastMirror(uint256 _token) external view returns (uint256) {
        bytes32 tokenActionHash = keccak256(
            abi.encode(_token, uint256(IKoruDao.Action.MIRROR))
        );

        return lastActionTime[tokenActionHash];
    }
}
