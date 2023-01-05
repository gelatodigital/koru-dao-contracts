import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../hardhat/utils";
import {
  getGelatoRelayAddress,
  getLensHubAddress,
} from "../hardhat/config/addresses";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments } = hre;
  const { deploy } = deployments;
  const { deployer } = await hre.getNamedAccounts();

  const lensHubAddress = getLensHubAddress(hre.network.name);
  const gelatoRelayAddress = getGelatoRelayAddress();

  const baseUri =
    "https://koru.infura-ipfs.io/ipfs/QmNZgnFPcuTStG8hL938h82A7Q8NHrtzA2Mjpc3anz6E31/";
  const isPaused = false;

  const maxSupply = 282;

  let hasRestrictions;
  let koruDaoProfileId;
  let minPubCount;
  let minFollowers;

  if (hre.network.name === "matic") {
    hasRestrictions = true;
    koruDaoProfileId = 42808;
    minPubCount = 2;
    minFollowers = 2;
  } else if (hre.network.name === "mumbai") {
    hasRestrictions = false;
    koruDaoProfileId = 16978;
    minPubCount = 0;
    minFollowers = 0;
  } else {
    //hardhat
    hasRestrictions = true;
    koruDaoProfileId = 42808;
    minPubCount = 0;
    minFollowers = 0;
  }

  if (hre.network.name !== "hardhat") {
    console.log(
      `Deploying KoruDaoNFT to ${hre.network.name}. Hit ctrl + c to abort`
    );

    console.log("hasRestrictions: ", hasRestrictions);
    console.log("maxSupply: ", maxSupply);
    console.log("koruDaoProfileId: ", koruDaoProfileId);
    console.log("minPubCount: ", minPubCount);
    console.log("minFollowers: ", minFollowers);
    await sleep(10000);
  }

  await deploy("KoruDaoNFT", {
    from: deployer,
    proxy: {
      owner: deployer,
      execute: {
        init: {
          methodName: "initialize",
          args: ["Koru Dao NFT", "KORUDAO", baseUri, isPaused],
        },
      },
    },
    args: [
      hasRestrictions,
      maxSupply,
      koruDaoProfileId,
      minPubCount,
      minFollowers,
      gelatoRelayAddress,
      lensHubAddress,
    ],
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip = hre.network.name !== "hardhat";
  return shouldSkip;
};

func.tags = ["KoruDaoNFT"];
