import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../hardhat/utils";
import {
  // getGelatoRelayAddress,
  getLensHubAddress,
} from "../hardhat/config/addresses";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments } = hre;
  const { deploy } = deployments;
  const { deployer } = await hre.getNamedAccounts();

  const lensHubAddress = getLensHubAddress(hre.network.name);
  // const gelatoRelayAddress = getGelatoRelayAddress();
  const gelatoRelayAddress = (
    await hre.ethers.getContract("KoruDaoRelayTransit")
  ).address; // using relay v0

  let hasRestrictions;
  let maxSupply;
  let koruDaoProfileId;
  let minPubCount;
  let minFollowers;

  if (hre.network.name === "matic") {
    hasRestrictions = true;
    maxSupply = 282;
    koruDaoProfileId = 42808;
    minPubCount = 2;
    minFollowers = 2;
  } else {
    hasRestrictions = false;
    maxSupply = 282;
    koruDaoProfileId = 16978;
    minPubCount = 2;
    minFollowers = 2;
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
