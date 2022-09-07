import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../hardhat/utils";
import {
  getGelatoRelayAddress,
  getLensHubAddress,
} from "../hardhat/config/addresses";
import { ethers } from "hardhat";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments } = hre;
  const { deploy } = deployments;
  const { deployer } = await hre.getNamedAccounts();

  const lensHubAddress = getLensHubAddress(hre.network.name);
  const gelatoRelayAddress = getGelatoRelayAddress();
  const koruDaoNftAddress = (await hre.ethers.getContract("KoruDaoNFT"))
    .address;

  let hasRestrictions;
  let postInterval;

  if (hre.network.name === "matic" || hre.network.name === "hardhat") {
    hasRestrictions = true;
    postInterval = 24 * 60 * 60; // 24 hrs
  } else {
    hasRestrictions = false;
    postInterval = 10 * 60; // 10 min
  }

  if (hre.network.name !== "hardhat") {
    console.log(
      `Deploying KoruDao to ${hre.network.name}. Hit ctrl + c to abort`
    );
    console.log("hasRestrictions: ", hasRestrictions);
    console.log("postInterval: ", postInterval);
    await sleep(10000);
  }

  await deploy("KoruDao", {
    from: deployer,
    proxy: {
      owner: deployer,
    },
    args: [
      hasRestrictions,
      koruDaoNftAddress,
      postInterval,
      lensHubAddress,
      gelatoRelayAddress,
    ],
    gasPrice: ethers.utils.parseUnits("120", "gwei"),
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip = hre.network.name !== "hardhat";
  return shouldSkip;
};

func.tags = ["KoruDao"];
func.dependencies = ["KoruDaoNFT"];
