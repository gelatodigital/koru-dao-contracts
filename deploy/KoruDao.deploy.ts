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

  const koruDaoNftAddress = (await hre.ethers.getContract("KoruDaoNFT"))
    .address;

  let postInterval;

  if (hre.network.name === "matic") {
    postInterval = 24 * 60 * 60; // 24 hrs
  } else {
    postInterval = 10 * 60; // 10 min
  }

  if (hre.network.name !== "hardhat") {
    console.log(
      `Deploying KoruDao to ${hre.network.name}. Hit ctrl + c to abort`
    );
    console.log("postInterval: ", postInterval);
    await sleep(10000);
  }

  await deploy("KoruDao", {
    from: deployer,
    proxy: {
      owner: deployer,
    },
    args: [postInterval, gelatoRelayAddress, koruDaoNftAddress, lensHubAddress],
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip = hre.network.name !== "hardhat";
  return shouldSkip;
};

func.tags = ["KoruDao"];
func.dependencies = ["KoruDaoNFT"];
