import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../hardhat/utils";
import {
  getGelatoMetaBoxAddress,
  getLensHubAddress,
} from "../hardhat/config/addresses";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  if (hre.network.name !== "hardhat") {
    console.log(
      `Deploying LensDao to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(10000);
  }

  const { deployments } = hre;
  const { deploy } = deployments;
  const { deployer } = await hre.getNamedAccounts();

  const lensHubAddress = getLensHubAddress(hre.network.name);
  const gelatoMetaBoxAddress = getGelatoMetaBoxAddress(hre.network.name);
  const lensDaoNftAddress = (await hre.ethers.getContract("LensDaoNFT"))
    .address;
  const postInterval = 12 * 60 * 60; // 12 hours

  await deploy("LensDao", {
    from: deployer,
    proxy: {
      owner: deployer,
    },
    args: [
      lensDaoNftAddress,
      postInterval,
      lensHubAddress,
      gelatoMetaBoxAddress,
    ],
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip = hre.network.name !== "hardhat";
  return shouldSkip;
};

func.tags = ["LensDao"];
func.dependencies = ["LensDaoNFT"];
