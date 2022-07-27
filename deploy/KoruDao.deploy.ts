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
      `Deploying KoruDao to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(10000);
  }

  const { deployments } = hre;
  const { deploy } = deployments;
  const { deployer } = await hre.getNamedAccounts();

  const lensHubAddress = getLensHubAddress(hre.network.name);
  const gelatoMetaBoxAddress = getGelatoMetaBoxAddress(hre.network.name);
  const koruDaoNftAddress = (await hre.ethers.getContract("KoruDaoNFT"))
    .address;
  const postInterval = 24 * 60 * 60; // 24 hours

  await deploy("KoruDao", {
    from: deployer,
    proxy: {
      owner: deployer,
    },
    args: [
      koruDaoNftAddress,
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

func.tags = ["KoruDao"];
func.dependencies = ["KoruDaoNFT"];
