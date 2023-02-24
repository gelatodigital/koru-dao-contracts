import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../hardhat/utils";
import { getGelatoRelayAddress } from "../hardhat/config/addresses";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments } = hre;
  const { deploy } = deployments;
  const { deployer } = await hre.getNamedAccounts();

  const koruDaoAddress = (await hre.ethers.getContract("KoruDao")).address;
  const koruDaoNftAddress = (await hre.ethers.getContract("KoruDaoNFT"))
    .address;

  const gelatoRelayAddress = getGelatoRelayAddress();

  let koruDaoProfileId;

  if (hre.network.name === "matic") {
    koruDaoProfileId = 42808;
  } else if (hre.network.name === "mumbai") {
    koruDaoProfileId = 27647;
  } else {
    //hardhat
    koruDaoProfileId = 42808;
  }

  let actionInterval;
  if (hre.network.name === "matic") {
    actionInterval = 12 * 60 * 60; // 12 hrs
  } else {
    actionInterval = 5 * 60; // 5 min
  }

  if (hre.network.name !== "hardhat") {
    console.log(
      `Deploying VoteRestrictionForPosting to ${hre.network.name}. Hit ctrl + c to abort`
    );
    console.log("actionInterval: ", actionInterval);
    await sleep(10000);
  }

  await deploy("VoteRestrictionForPosting", {
    from: deployer,
    proxy: {
      owner: deployer,
    },
    args: [
      gelatoRelayAddress,
      actionInterval,
      5,
      koruDaoAddress,
      koruDaoNftAddress,
      koruDaoProfileId,
    ],
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip = hre.network.name !== "hardhat";
  return shouldSkip;
};

func.tags = ["VoteRestrictionForPosting"];
