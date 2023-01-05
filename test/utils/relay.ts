import hre = require("hardhat");
const { ethers } = hre;
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { getGelatoRelayAddress } from "../../hardhat/config/addresses";

// prettier-ignore
const relayAbi = [{"inputs":[{"internalType":"address","name":"_gelato","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"target","type":"address"},{"indexed":true,"internalType":"bytes32","name":"correlationId","type":"bytes32"}],"name":"LogCallWithSyncFeeERC2771","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"sponsor","type":"address"},{"indexed":true,"internalType":"address","name":"target","type":"address"},{"indexed":true,"internalType":"address","name":"feeToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"oneBalanceChainId","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"nativeToFeeTokenXRateNumerator","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"nativeToFeeTokenXRateDenominator","type":"uint256"},{"indexed":false,"internalType":"bytes32","name":"correlationId","type":"bytes32"}],"name":"LogUseGelato1Balance","type":"event"},{"inputs":[],"name":"CALL_WITH_SYNC_FEE_ERC2771_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"SPONSORED_CALL_ERC2771_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"components":[{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"address","name":"target","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"},{"internalType":"address","name":"user","type":"address"},{"internalType":"uint256","name":"userNonce","type":"uint256"},{"internalType":"uint256","name":"userDeadline","type":"uint256"}],"internalType":"struct CallWithERC2771","name":"_call","type":"tuple"},{"internalType":"address","name":"_feeToken","type":"address"},{"internalType":"bytes","name":"_userSignature","type":"bytes"},{"internalType":"bool","name":"_isRelayContext","type":"bool"},{"internalType":"bytes32","name":"_correlationId","type":"bytes32"}],"name":"callWithSyncFeeERC2771","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"gelato","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"components":[{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"address","name":"target","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"},{"internalType":"address","name":"user","type":"address"},{"internalType":"uint256","name":"userNonce","type":"uint256"},{"internalType":"uint256","name":"userDeadline","type":"uint256"}],"internalType":"struct CallWithERC2771","name":"_call","type":"tuple"},{"internalType":"address","name":"_sponsor","type":"address"},{"internalType":"address","name":"_feeToken","type":"address"},{"internalType":"uint256","name":"_oneBalanceChainId","type":"uint256"},{"internalType":"bytes","name":"_userSignature","type":"bytes"},{"internalType":"uint256","name":"_nativeToFeeTokenXRateNumerator","type":"uint256"},{"internalType":"uint256","name":"_nativeToFeeTokenXRateDenominator","type":"uint256"},{"internalType":"bytes32","name":"_correlationId","type":"bytes32"}],"name":"sponsoredCallERC2771","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"userNonce","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}];
const relayAddress = getGelatoRelayAddress();

export const signRelayTransaction = async (
  signer: SignerWithAddress,
  data: string,
  target: string
) => {
  const relay = await ethers.getContractAt(relayAbi, relayAddress);

  const nonce = await relay.userNonce(signer.address);

  if (!signer.provider) throw new Error("Signer has no provider");
  const chainId = (await signer.provider.getNetwork()).chainId;
  const deadline = (await signer.provider.getBlock("latest")).timestamp + 300;

  const domain = {
    name: "GelatoRelayERC2771",
    version: "1",
    chainId,
    verifyingContract: relayAddress,
  };

  const type = {
    SponsoredCallERC2771: [
      { name: "chainId", type: "uint256" },
      { name: "target", type: "address" },
      { name: "data", type: "bytes" },
      { name: "user", type: "address" },
      { name: "userNonce", type: "uint256" },
      { name: "userDeadline", type: "uint256" },
    ],
  };

  const message = {
    userNonce: nonce.toString(),
    userDeadline: deadline,
    chainId,
    target,
    data: data,
    user: signer.address,
  };

  const signature = await signer._signTypedData(domain, type, message);
  return { signature, message };
};
