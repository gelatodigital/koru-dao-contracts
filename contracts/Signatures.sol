// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

//solhint-disable private-vars-leading-underscore
//solhint-disable max-line-length
//solhint-disable not-rely-on-time
abstract contract Signatures {
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    bytes32 internal constant EIP712_NAME_HASH =
        keccak256("KoruDaoRelayTransit");
    bytes32 internal constant EIP712_VERSION_HASH = keccak256("1");
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 internal constant MINT_WITH_SIG_TYPEHASH =
        keccak256("Mint(address user,uint256 nonce,uint256 deadline)");
    bytes32 internal constant POST_WITH_SIG_TYPEHASH =
        keccak256(
            "Post(address user,uint256 nonce,uint256 deadline,uint256 profileId,string contentURI,address collectModule,bytes collectModuleInitData,address referenceModule,bytes referenceModuleInitData)"
        );

    function _validateRecoveredAddress(
        bytes32 digest,
        address expectedAddress,
        EIP712Signature calldata sig
    ) internal view {
        require(sig.deadline >= block.timestamp, "Signatures: sig expired");

        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);

        require(
            recoveredAddress == expectedAddress &&
                recoveredAddress != address(0),
            "Signatures: invalid sig"
        );
    }

    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    EIP712_NAME_HASH,
                    EIP712_VERSION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _calculateDigest(bytes32 hashedMessage)
        internal
        view
        returns (bytes32)
    {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _calculateDomainSeparator(),
                    hashedMessage
                )
            );
        }
        return digest;
    }
}
