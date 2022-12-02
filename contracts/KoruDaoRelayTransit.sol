// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {Signatures} from "./Signatures.sol";
import {GelatoBytes} from "./vendor/gelato/GelatoBytes.sol";
import {DataTypes} from "./libraries/LensDataTypes.sol";
import {_transfer, ETH} from "./functions/FUtils.sol";
import {IKoruDao} from "./interfaces/IKoruDao.sol";
import {IKoruDaoNFT} from "./interfaces/IKoruDaoNFT.sol";

//solhint-disable no-empty-blocks
//solhint-disable not-rely-on-time
contract KoruDaoRelayTransit is Signatures {
    uint256 public immutable maxFee;
    address public immutable gelatoRelay;
    address public immutable koruDao;
    address public immutable koruDaoNFT;
    mapping(address => uint256) public nonces;

    event LogPost(address user, uint256 fee, uint256 time);
    event LogMint(address user, uint256 fee, uint256 time);

    modifier onlyGelatoRelay() {
        require(
            msg.sender == gelatoRelay,
            "KoruDaoRelayTransit: Only gelato relay"
        );
        _;
    }

    constructor(
        uint256 _maxFee,
        address _gelatoRelay,
        address _koruDao,
        address _koruDaoNFT
    ) {
        maxFee = _maxFee;
        gelatoRelay = _gelatoRelay;
        koruDao = _koruDao;
        koruDaoNFT = _koruDaoNFT;
    }

    receive() external payable {}

    function post(
        address _user,
        uint256 _fee,
        DataTypes.PostData calldata _postVars,
        EIP712Signature calldata _sig
    ) external onlyGelatoRelay {
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            POST_WITH_SIG_TYPEHASH,
                            _user,
                            nonces[_user]++,
                            _sig.deadline,
                            _postVars.profileId,
                            keccak256(bytes(_postVars.contentURI)),
                            _postVars.collectModule,
                            keccak256(_postVars.collectModuleInitData),
                            _postVars.referenceModule,
                            keccak256(_postVars.referenceModuleInitData)
                        )
                    )
                ),
                _user,
                _sig
            );
        }

        _post(_user, _postVars);

        uint256 feeUsed = _payRelayFee(_fee);

        emit LogPost(_user, feeUsed, block.timestamp);
    }

    function mint(
        address _user,
        uint256 _fee,
        EIP712Signature calldata _sig
    ) external onlyGelatoRelay {
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            MINT_WITH_SIG_TYPEHASH,
                            _user,
                            nonces[_user]++,
                            _sig.deadline
                        )
                    )
                ),
                _user,
                _sig
            );
        }

        _mint(_user);

        uint256 feeUsed = _payRelayFee(_fee);

        emit LogMint(_user, feeUsed, block.timestamp);
    }

    function _post(address _user, DataTypes.PostData calldata _postVars)
        private
    {
        bytes memory postData = abi.encodeWithSelector(
            IKoruDao.post.selector,
            _postVars
        );

        (bool success, bytes memory returnData) = koruDao.call(
            abi.encodePacked(postData, _user)
        );

        if (!success)
            GelatoBytes.revertWithError(returnData, "KoruDaoRelayTransit: ");
    }

    function _mint(address _user) private {
        (bool success, bytes memory returnData) = koruDaoNFT.call(
            abi.encodePacked(IKoruDaoNFT.mint.selector, _user)
        );

        if (!success)
            GelatoBytes.revertWithError(returnData, "KoruDaoRelayTransit: ");
    }

    function _payRelayFee(uint256 _fee) private returns (uint256 feeUsed) {
        feeUsed = _fee > maxFee || _fee == 0 ? maxFee : _fee;

        _transfer(payable(gelatoRelay), ETH, feeUsed);
    }
}
