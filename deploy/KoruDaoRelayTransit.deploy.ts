import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../hardhat/utils";
import { getGelatoRelayV0TransitAddress } from "../hardhat/config/addresses";
import { ethers } from "hardhat";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments } = hre;
  const { deploy } = deployments;
  const { deployer } = await hre.getNamedAccounts();

  const koruDaoAddress = (await ethers.getContract("KoruDao")).address;
  const koruDaoNFTAddress = (await ethers.getContract("KoruDaoNFT")).address;
  const fee = ethers.utils.parseEther("0.1");
  const gelatoRelayV0TransitAddress = getGelatoRelayV0TransitAddress(
    hre.network.name
  );

  if (hre.network.name !== "hardhat") {
    console.log(
      `Deploying KoruDaoRelayTransit to ${hre.network.name}. Hit ctrl + c to abort`
    );
    console.log("fee: ", fee);
    console.log("gelatoRelayV0TransitAddress: ", gelatoRelayV0TransitAddress);
    console.log("koruDaoAddress: ", koruDaoAddress);
    console.log("koruDaoNFTAddress: ", koruDaoNFTAddress);
    await sleep(10000);
  }

  await deploy("KoruDaoRelayTransit", {
    from: deployer,
    proxy: {
      proxyContract: "EIP173ProxyWithCustomReceive",
      owner: deployer,
    },
    args: [fee, gelatoRelayV0TransitAddress, koruDaoAddress, koruDaoNFTAddress],
    log: true,
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip = hre.network.name !== "hardhat";
  return shouldSkip;
};

func.tags = ["KoruDaoRelayTransit"];
