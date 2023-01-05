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

  if (hre.network.name !== "hardhat") {
    console.log(
      `Deploying KoruDao to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(10000);
  }

  await deploy("KoruDao", {
    from: deployer,
    proxy: {
      owner: deployer,
    },
    args: [gelatoRelayAddress, lensHubAddress],
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip = hre.network.name !== "hardhat";
  return shouldSkip;
};

func.tags = ["KoruDao"];
func.dependencies = ["KoruDaoNFT"];
