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

  let hasRestrictions;
  let maxSupply;
  if (hre.network.name === "matic" || hre.network.name === "hardhat") {
    hasRestrictions = true;
    maxSupply = 282;
  } else {
    hasRestrictions = false;
    maxSupply = 282;
  }

  if (hre.network.name !== "hardhat") {
    console.log(
      `Deploying KoruDaoNFT to ${hre.network.name}. Hit ctrl + c to abort`
    );
    console.log("hasRestrictions: ", hasRestrictions);
    console.log("maxSupply: ", maxSupply);
    await sleep(10000);
  }

  await deploy("KoruDaoNFT", {
    from: deployer,
    proxy: {
      owner: deployer,
    },
    args: [hasRestrictions, maxSupply, lensHubAddress, gelatoRelayAddress],
    gasPrice: ethers.utils.parseUnits("120", "gwei"),
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip = hre.network.name !== "hardhat";
  return shouldSkip;
};

func.tags = ["KoruDaoNFT"];
