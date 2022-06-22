/* eslint-disable @typescript-eslint/no-explicit-any */
import { Signer } from "@ethersproject/abstract-signer";
import { expect } from "chai";
import hre = require("hardhat");
const { ethers, deployments } = hre;
import {
  LensDao,
  LensDaoNFT,
  IMockProfileCreationProxy,
  IGelatoMetaBox,
  ILensHub,
} from "../typechain";
import { GelatoRelaySDK } from "@gelatonetwork/gelato-relay-sdk";
import { BigNumber, Wallet } from "ethers";
import {
  getGelatoAddress,
  getGelatoMetaBoxAddress,
  getLensHubAddress,
} from "../hardhat/config/addresses";

const lensProfileCreatorAddress = "0x420f0257D43145bb002E69B14FF2Eb9630Fc4736";
const freeCollectModuleAddress = "0x0BE6bD7092ee83D44a6eC1D949626FeE48caB30c";

const gelatoMetaBoxAddress = getGelatoMetaBoxAddress("mumbai");
const gelatoAddress = getGelatoAddress("mumbai");
const lensHubAddress = getLensHubAddress("mumbai");

const chainId = 80001;
const paymentType = 2;
const maxFee = ethers.utils.parseEther("1").toString();
const gas = "20000000";
const ETH = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
const txFee = 0;
const taskId =
  "0x6d707c5a3def3c26511b9d16a1291ca078f5e891336180d8fc5a4cf0b5736cfa";

describe("LensDao test", function () {
  this.timeout(0);

  let deployer: Signer;
  let gelato: Signer;
  let sponsor: Wallet;
  let profileOwner: Wallet;
  let nonProfileOwner: Wallet;

  let sponsorAddress: string;
  let profileOwnerAddress: string;
  let nonProfileOwnerAddress: string;

  let lensDao: LensDao;
  let lensDaoNFT: LensDaoNFT;
  let lensProfileCreator: IMockProfileCreationProxy;
  let gelatoMetaBox: IGelatoMetaBox;
  let lensHub: ILensHub;

  beforeEach(async function () {
    await deployments.fixture();
    [deployer] = await ethers.getSigners();
    sponsor = new ethers.Wallet(
      ethers.Wallet.createRandom().privateKey,
      ethers.provider
    );
    profileOwner = new ethers.Wallet(
      ethers.Wallet.createRandom().privateKey,
      ethers.provider
    );
    nonProfileOwner = new ethers.Wallet(
      ethers.Wallet.createRandom().privateKey,
      ethers.provider
    );

    await deployer.sendTransaction({
      to: sponsor.address,
      value: ethers.utils.parseEther("100"),
    });
    await deployer.sendTransaction({
      to: profileOwner.address,
      value: ethers.utils.parseEther("100"),
    });
    await deployer.sendTransaction({
      to: nonProfileOwner.address,
      value: ethers.utils.parseEther("100"),
    });

    sponsorAddress = await sponsor.getAddress();
    profileOwnerAddress = await profileOwner.getAddress();
    nonProfileOwnerAddress = await nonProfileOwner.getAddress();

    lensDao = await ethers.getContract("LensDao");
    lensDaoNFT = await ethers.getContract("LensDaoNFT");
    lensProfileCreator = await ethers.getContractAt(
      "IMockProfileCreationProxy",
      lensProfileCreatorAddress
    );
    gelatoMetaBox = await ethers.getContractAt(
      "IGelatoMetaBox",
      gelatoMetaBoxAddress
    );
    lensHub = await ethers.getContractAt("ILensHub", lensHubAddress);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [gelatoAddress],
    });
    gelato = await ethers.getSigner(gelatoAddress);

    // Create Lens Profile for user
    await lensProfileCreator.connect(deployer).proxyCreateProfile({
      to: profileOwnerAddress,
      handle: "lensdaouser",
      imageURI: "https://",
      followModule: "0x0000000000000000000000000000000000000000",
      followModuleInitData: "0x",
      followNFTURI: "ipfs://",
    });

    // Create Lens Profile for LensDao
    await lensProfileCreator.connect(deployer).proxyCreateProfile({
      to: sponsorAddress,
      handle: "lensdao",
      imageURI: "https://",
      followModule: "0x0000000000000000000000000000000000000000",
      followModuleInitData: "0x",
      followNFTURI: "ipfs://",
    });

    expect(await lensDao.hasLensProfile(sponsorAddress)).to.be.true;
    expect(await lensDao.hasLensProfile(profileOwnerAddress)).to.be.true;

    // Delegate posting rights to lensDao
    const lensProfileid = await lensHub.getProfileIdByHandle("lensdao.test");
    await lensHub
      .connect(sponsor)
      .setDispatcher(lensProfileid, lensDao.address);

    expect(await lensHub.getDispatcher(lensProfileid)).to.be.eql(
      lensDao.address
    );
  });

  it("mint - lens profile owner", async () => {
    const mintData = lensDaoNFT.interface.encodeFunctionData("mint");
    const { request, digest } = getReqAndDigest(
      lensDaoNFT.address,
      mintData,
      profileOwnerAddress
    );

    const sponsorSignature = ethers.utils.joinSignature(
      sponsor._signingKey().signDigest(digest)
    );
    const userSignature = ethers.utils.joinSignature(
      profileOwner._signingKey().signDigest(digest)
    );

    await gelatoMetaBox
      .connect(gelato)
      .metaTxRequestGasTankFee(
        request,
        userSignature,
        sponsorSignature,
        txFee,
        taskId
      );
    expect(await lensDaoNFT.balanceOf(profileOwnerAddress)).to.be.eql(
      ethers.BigNumber.from("1")
    );
  });

  it("mint - non lens profile owner", async () => {
    const mintData = lensDaoNFT.interface.encodeFunctionData("mint");
    const { request, digest } = getReqAndDigest(
      lensDaoNFT.address,
      mintData,
      profileOwnerAddress
    );

    const sponsorSignature = ethers.utils.joinSignature(
      sponsor._signingKey().signDigest(digest)
    );
    const userSignature = ethers.utils.joinSignature(
      nonProfileOwner._signingKey().signDigest(digest)
    );

    await expect(
      gelatoMetaBox
        .connect(gelato)
        .metaTxRequestGasTankFee(
          request,
          userSignature,
          sponsorSignature,
          txFee,
          taskId
        )
    ).to.be.reverted;
  });

  it("mint - only one", async () => {
    await lensDaoNFT.connect(profileOwner).mint();

    await expect(lensDaoNFT.connect(profileOwner).mint()).to.be.revertedWith(
      "LensDaoNFT: One per wallet"
    );
  });

  it("post - with lensDaoNFT", async () => {
    await lensDaoNFT.connect(profileOwner).mint();
    const lensDaoNftId = await lensDaoNFT.tokenOfOwnerByIndex(
      profileOwnerAddress,
      0
    );

    const { postData } = await getPostData(lensDaoNftId);

    const { request, digest } = getReqAndDigest(
      lensDao.address,
      postData,
      profileOwnerAddress
    );

    const sponsorSignature = ethers.utils.joinSignature(
      sponsor._signingKey().signDigest(digest)
    );
    const userSignature = ethers.utils.joinSignature(
      profileOwner._signingKey().signDigest(digest)
    );

    await gelatoMetaBox
      .connect(gelato)
      .metaTxRequestGasTankFee(
        request,
        userSignature,
        sponsorSignature,
        txFee,
        taskId
      );
  });

  it("post - without lensDaoNFT", async () => {
    await lensDaoNFT.connect(profileOwner).mint();
    const lensDaoNftId = await lensDaoNFT.tokenOfOwnerByIndex(
      profileOwnerAddress,
      0
    );

    const { postData, postDataObj } = await getPostData(lensDaoNftId);

    const { request, digest } = getReqAndDigest(
      lensDao.address,
      postData,
      nonProfileOwnerAddress
    );

    const sponsorSignature = ethers.utils.joinSignature(
      sponsor._signingKey().signDigest(digest)
    );
    const userSignature = ethers.utils.joinSignature(
      nonProfileOwner._signingKey().signDigest(digest)
    );

    await expect(
      gelatoMetaBox
        .connect(gelato)
        .metaTxRequestGasTankFee(
          request,
          userSignature,
          sponsorSignature,
          txFee,
          taskId
        )
    ).to.be.reverted;

    await expect(lensDao.post(lensDaoNftId, postDataObj)).to.be.revertedWith(
      "Not owner"
    );
  });

  it("post - too frequent", async () => {
    await lensDaoNFT.connect(profileOwner).mint();
    const lensDaoNftId = await lensDaoNFT.tokenOfOwnerByIndex(
      profileOwnerAddress,
      0
    );

    const { postDataObj } = await getPostData(lensDaoNftId);

    await lensDao.connect(profileOwner).post(lensDaoNftId, postDataObj);

    await expect(
      lensDao.connect(profileOwner).post(lensDaoNftId, postDataObj)
    ).to.be.revertedWith("LensDao: Post too frequent");
  });

  const getReqAndDigest = (
    target: string,
    data: string,
    userAddress: string
  ) => {
    const metaTxRequest = GelatoRelaySDK.metaTxRequest(
      chainId,
      target,
      data,
      ETH,
      paymentType,
      maxFee,
      gas,
      userAddress,
      0,
      sponsorAddress
    );

    const digest = GelatoRelaySDK.getMetaTxRequestDigestToSign(metaTxRequest);

    return { request: metaTxRequest, digest };
  };

  const getPostData = async (lensDaoNftId: BigNumber) => {
    const profileId = await lensHub.getProfileIdByHandle("lensdao.test");
    const contentURI = "https://";
    const collectModule = freeCollectModuleAddress;
    const collectModuleInitData = ethers.utils.defaultAbiCoder.encode(
      ["bool"],
      [false]
    );
    const referenceModule = "0x0000000000000000000000000000000000000000";
    const referenceModuleInitData = "0x";

    const postDataObj = {
      profileId,
      contentURI,
      collectModule,
      collectModuleInitData,
      referenceModule,
      referenceModuleInitData,
    };

    const postData = lensDao.interface.encodeFunctionData("post", [
      lensDaoNftId,
      postDataObj,
    ]);

    return { postData, postDataObj };
  };
});
