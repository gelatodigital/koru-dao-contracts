/* eslint-disable @typescript-eslint/naming-convention */
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { address as mainnetOps } from "../../deployments/mainnet/Ops.json";
import { GelatoRelaySDK } from "@gelatonetwork/gelato-relay-sdk";

export const getGelatoMetaBoxAddress = (network: string): string => {
  let chainId;
  switch (network) {
    case "matic":
      chainId = 137;
      break;
    case "mumbai":
    case "hardhat":
      chainId = 80001;
      break;
    default:
      throw new Error("No gelato meta box address for network");
  }

  const { address } = GelatoRelaySDK.getMetaBoxAddressAndABI(chainId);
  return address;
};
export const getLensHubAddress = (network: string): string => {
  const LENS_HUB_MATIC = "0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d";
  const LENS_HUB_MUMBAI = "0x60Ae865ee4C725cd04353b5AAb364553f56ceF82";

  switch (network) {
    case "matic":
      return LENS_HUB_MATIC;
    case "mumbai":
    case "hardhat":
      return LENS_HUB_MUMBAI;
    default:
      throw new Error("No lens hub address for network");
  }
};

export const getGelatoAddress = (network: string): string => {
  const GELATO_MAINNET = "0x3caca7b48d0573d793d3b0279b5f0029180e83b6";
  const GELATO_MATIC = "0x7598e84B2E114AB62CAB288CE5f7d5f6bad35BbA";
  const GELATO_FANTOM = "0xebA27A2301975FF5BF7864b99F55A4f7A457ED10";
  const GELATO_AVALANCHE = "0x7C5c4Af1618220C090A6863175de47afb20fa9Df";
  const GELATO_ARBITRUM = "0x4775aF8FEf4809fE10bf05867d2b038a4b5B2146";
  const GELATO_BSC = "0x7C5c4Af1618220C090A6863175de47afb20fa9Df";
  const GELATO_GNOSIS = "0x29b6603D17B9D8f021EcB8845B6FD06E1Adf89DE";
  const GELATO_OPTIMISM = "0x01051113D81D7d6DA508462F2ad6d7fD96cF42Ef";
  const GELATO_MOONBEAM = "0x91f2A140cA47DdF438B9c583b7E71987525019bB";

  const GELATO_ROPSTEN = "0xCc4CcD69D31F9FfDBD3BFfDe49c6aA886DaB98d9";
  const GELATO_RINKEBY = "0x0630d1b8C2df3F0a68Df578D02075027a6397173";
  const GELATO_GOERLI = "0x683913B3A32ada4F8100458A3E1675425BdAa7DF";
  const GELATO_KOVAN = "0xDf592cB2d32445F8e831d211AB20D3233cA41bD8";
  const GELATO_MUMBAI = "0x25aD59adbe00C2d80c86d01e2E05e1294DA84823";

  switch (network) {
    case "mainnet":
      return GELATO_MAINNET;
    case "ropsten":
      return GELATO_ROPSTEN;
    case "rinkeby":
      return GELATO_RINKEBY;
    case "goerli":
      return GELATO_GOERLI;
    case "kovan":
      return GELATO_KOVAN;
    case "matic":
      return GELATO_MATIC;
    case "fantom":
      return GELATO_FANTOM;
    case "avalanche":
      return GELATO_AVALANCHE;
    case "arbitrum":
      return GELATO_ARBITRUM;
    case "bsc":
      return GELATO_BSC;
    case "gnosis":
      return GELATO_GNOSIS;
    case "mumbai":
      return GELATO_MUMBAI;
    case "optimism":
      return GELATO_OPTIMISM;
    case "moonbeam":
      return GELATO_MOONBEAM;
    case "hardhat":
      return GELATO_MAINNET;
    default:
      throw new Error("No gelato address for network");
  }
};

export const getOpsAddress = async (
  hre: HardhatRuntimeEnvironment
): Promise<string> => {
  const network = hre.network.name;

  if (network == "mainnet" || network == "hardhat") return mainnetOps;

  return (await hre.ethers.getContract("Ops")).address;
};

export const getTaskTreasuryAddress = async (
  hre: HardhatRuntimeEnvironment
): Promise<string> => {
  const network = hre.network.name;

  if (
    network == "mainnet" ||
    network == "ropsten" ||
    network == "rinkeby" ||
    network == "goerli"
  )
    return (await hre.ethers.getContract("TaskTreasury")).address;

  return (await hre.ethers.getContract("TaskTreasuryL2")).address;
};