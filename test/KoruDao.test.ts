/* eslint-disable @typescript-eslint/no-explicit-any */
import { Signer } from "@ethersproject/abstract-signer";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import hre = require("hardhat");
import {
  getGelatoRelayAddress,
  getLensHubAddress,
} from "../hardhat/config/addresses";
const { ethers, deployments } = hre;
import {
  KoruDao,
  TimeRestrictionForPosting,
  KoruDaoNFT,
  ILensHub,
} from "../typechain";
import { fastForwardTime } from "./utils";
import { signRelayTransaction } from "./utils/relay";

// prettier-ignore
const relayAbi = [{"inputs":[{"internalType":"address","name":"_gelato","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"target","type":"address"},{"indexed":true,"internalType":"bytes32","name":"correlationId","type":"bytes32"}],"name":"LogCallWithSyncFeeERC2771","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"sponsor","type":"address"},{"indexed":true,"internalType":"address","name":"target","type":"address"},{"indexed":true,"internalType":"address","name":"feeToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"oneBalanceChainId","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"nativeToFeeTokenXRateNumerator","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"nativeToFeeTokenXRateDenominator","type":"uint256"},{"indexed":false,"internalType":"bytes32","name":"correlationId","type":"bytes32"}],"name":"LogUseGelato1Balance","type":"event"},{"inputs":[],"name":"CALL_WITH_SYNC_FEE_ERC2771_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"SPONSORED_CALL_ERC2771_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"components":[{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"address","name":"target","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"},{"internalType":"address","name":"user","type":"address"},{"internalType":"uint256","name":"userNonce","type":"uint256"},{"internalType":"uint256","name":"userDeadline","type":"uint256"}],"internalType":"struct CallWithERC2771","name":"_call","type":"tuple"},{"internalType":"address","name":"_feeToken","type":"address"},{"internalType":"bytes","name":"_userSignature","type":"bytes"},{"internalType":"bool","name":"_isRelayContext","type":"bool"},{"internalType":"bytes32","name":"_correlationId","type":"bytes32"}],"name":"callWithSyncFeeERC2771","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"gelato","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"components":[{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"address","name":"target","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"},{"internalType":"address","name":"user","type":"address"},{"internalType":"uint256","name":"userNonce","type":"uint256"},{"internalType":"uint256","name":"userDeadline","type":"uint256"}],"internalType":"struct CallWithERC2771","name":"_call","type":"tuple"},{"internalType":"address","name":"_sponsor","type":"address"},{"internalType":"address","name":"_feeToken","type":"address"},{"internalType":"uint256","name":"_oneBalanceChainId","type":"uint256"},{"internalType":"bytes","name":"_userSignature","type":"bytes"},{"internalType":"uint256","name":"_nativeToFeeTokenXRateNumerator","type":"uint256"},{"internalType":"uint256","name":"_nativeToFeeTokenXRateDenominator","type":"uint256"},{"internalType":"bytes32","name":"_correlationId","type":"bytes32"}],"name":"sponsoredCallERC2771","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"userNonce","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}];
const relayAddress = getGelatoRelayAddress();
const chainId = hre.network.config.chainId;
const lensHubAddress = getLensHubAddress("matic");
const gelatoAddress = "0x7598e84b2e114ab62cab288ce5f7d5f6bad35bba";
const lensHandleOwnerAddress = "0x1DD1133aE3c46513A8eB85BC67331B6e550f786d";
const koruDaoLensId = 42808;
const koruDaoLensHandleOwnerAddress =
  "0x3e6Af7430845e430F49D7c8D0217540F0b012f99";

describe("KoruDao test", function () {
  this.timeout(0);

  let user: SignerWithAddress;
  let lensHandleOwner: Signer;
  let gelato: Signer;
  let koruDaoLensHandleOwner: Signer;

  let koruDao: KoruDao;
  let koruDaoNft: KoruDaoNFT;
  let timeRestriction: TimeRestrictionForPosting;
  let relay: any;
  let lensHub: ILensHub;

  beforeEach(async function () {
    await deployments.fixture();

    [user] = await ethers.getSigners();

    koruDao = <KoruDao>await ethers.getContract("KoruDao");
    koruDaoNft = <KoruDaoNFT>await ethers.getContract("KoruDaoNFT");
    timeRestriction = <TimeRestrictionForPosting>(
      await ethers.getContract("TimeRestrictionForPosting")
    );

    lensHub = await ethers.getContractAt("ILensHub", lensHubAddress);
    relay = await ethers.getContractAt(relayAbi, relayAddress);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [gelatoAddress],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [lensHandleOwnerAddress],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [koruDaoLensHandleOwnerAddress],
    });

    gelato = ethers.provider.getSigner(gelatoAddress);
    lensHandleOwner = ethers.provider.getSigner(lensHandleOwnerAddress);
    koruDaoLensHandleOwner = ethers.provider.getSigner(
      koruDaoLensHandleOwnerAddress
    );

    await koruDao.setActionRestriction(0, timeRestriction.address);
    await lensHub
      .connect(koruDaoLensHandleOwner)
      ["safeTransferFrom(address,address,uint256)"](
        koruDaoLensHandleOwnerAddress,
        koruDao.address,
        koruDaoLensId
      );

    await koruDao.setDefaultProfile(koruDaoLensId);
  });

  it("mint - with lens handle", async () => {
    await transferLensHandleToUser();

    await expect(mint()).to.not.be.reverted;

    await expect(koruDaoNft.tokenOfOwnerByIndex(user.address, 0)).to.not.be
      .reverted;
  });

  it("mint - no lens handle", async () => {
    await expect(mint()).to.be.revertedWith(
      "GelatoRelayERC2771.sponsoredCallERC2771:MintRestrictions: Wallet does not have default profile"
    );
  });

  it("mint - more than once", async () => {
    await transferLensHandleToUser();

    await expect(mint()).to.not.be.reverted;

    await expect(koruDaoNft.tokenOfOwnerByIndex(user.address, 0)).to.not.be
      .reverted;

    await expect(mint()).to.be.revertedWith(
      "GelatoRelayERC2771.sponsoredCallERC2771:MintRestrictions: Already minted with lens profile"
    );
  });

  it("post - with koruDao nft", async () => {
    await transferLensHandleToUser();

    await mint();

    await expect(post()).to.not.be.reverted;
  });

  it("post - no koruDao nft", async () => {
    await expect(post()).to.be.revertedWith(
      "GelatoRelayERC2771.sponsoredCallERC2771:TimeRestrictionForPosting: No KoruDaoNft"
    );
  });

  it("post - interval not elapsed", async () => {
    await transferLensHandleToUser();

    await mint();

    await post();

    await expect(post()).to.be.revertedWith(
      "GelatoRelayERC2771.sponsoredCallERC2771:TimeRestrictionForPosting: Too frequent"
    );
  });

  it("post - interval elapsed", async () => {
    await transferLensHandleToUser();

    await mint();

    await post();

    const interval = await timeRestriction.actionInterval();
    await fastForwardTime(Number(interval));

    await expect(post()).to.not.be.reverted;
  });

  const mint = async () => {
    const mintData = koruDaoNft.interface.encodeFunctionData("mint");
    const mintTarget = koruDaoNft.address;

    const mint = await signRelayTransaction(user, mintData, mintTarget);

    await relay
      .connect(gelato)
      .sponsoredCallERC2771(
        mint.message,
        user.address,
        ethers.constants.AddressZero,
        chainId,
        mint.signature,
        0,
        0,
        ethers.constants.HashZero
      );
  };

  const post = async () => {
    const postData = {
      profileId: koruDaoLensId,
      contentURI: "https://",
      collectModule: "0x23b9467334bEb345aAa6fd1545538F3d54436e96", // mumbai free collect module - https://docs.lens.xyz/docs/deployed-contract-addresses
      collectModuleInitData:
        "0x0000000000000000000000000000000000000000000000000000000000000000",
      referenceModule: ethers.constants.AddressZero,
      referenceModuleInitData: "0x",
    };

    const data = koruDao.interface.encodeFunctionData("post", [postData]);
    const target = koruDao.address;

    const { message, signature } = await signRelayTransaction(
      user,
      data,
      target
    );

    await relay
      .connect(gelato)
      .sponsoredCallERC2771(
        message,
        user.address,
        ethers.constants.AddressZero,
        chainId,
        signature,
        0,
        0,
        ethers.constants.HashZero
      );
  };

  const transferLensHandleToUser = async () => {
    const lensHandleId = await lensHub.defaultProfile(lensHandleOwnerAddress);
    await lensHub
      .connect(lensHandleOwner)
      ["safeTransferFrom(address,address,uint256)"](
        lensHandleOwnerAddress,
        user.address,
        lensHandleId.toString()
      );

    await lensHub.setDefaultProfile(lensHandleId);
    await lensHub.follow(
      [koruDaoLensId.toString()],
      [ethers.constants.HashZero]
    );
  };
});
