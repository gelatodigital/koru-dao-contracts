import { HardhatUserConfig } from "hardhat/config";

// PLUGINS
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-deploy";

// Process Env Variables
import * as dotenv from "dotenv";
dotenv.config({ path: __dirname + "/.env" });

// Libraries
import assert from "assert";

// @dev Put this in .env
const ALCHEMY_ID = process.env.ALCHEMY_ID;
assert.ok(ALCHEMY_ID, "no Alchemy ID in process.env");

// @dev fill this out
const PK = process.env.PK;
const ETHERSCAN_API = process.env.ETHERSCAN_MATIC_API;

// ================================= CONFIG =========================================
const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",

  namedAccounts: {
    deployer: {
      default: 0,
    },
  },

  networks: {
    hardhat: {
      // Standard config
      // timeout: 150000,
      forking: {
        url: `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
        blockNumber: 37688900,
      },
    },
    arbitrum: {
      url: `https://arb-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
      chainId: 42161,
      accounts: PK ? [PK] : [],
    },
    avalanche: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      chainId: 43114,
      accounts: PK ? [PK] : [],
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      accounts: PK ? [PK] : [],
    },
    fantom: {
      accounts: PK ? [PK] : [],
      chainId: 250,
      url: `https://rpcapi.fantom.network/`,
    },
    gnosis: {
      url: "https://rpc.gnosischain.com",
      chainId: 100,
      accounts: PK ? [PK] : [],
    },
    goerli: {
      accounts: PK ? [PK] : [],
      chainId: 5,
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    kovan: {
      accounts: PK ? [PK] : [],
      chainId: 42,
      url: `https://eth-kovan.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    mainnet: {
      accounts: PK ? [PK] : [],
      chainId: 1,
      url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    matic: {
      url: `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
      chainId: 137,
      accounts: PK ? [PK] : [],
    },
    moonbeam: {
      url: `https://rpc.api.moonbeam.network`,
      chainId: 1284,
      accounts: PK ? [PK] : [],
    },
    moonriver: {
      url: `https://rpc.api.moonriver.moonbeam.network`,
      chainId: 1285,
      accounts: PK ? [PK] : [],
    },
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_ID}`,
      chainId: 80001,
      accounts: PK ? [PK] : [],
    },
    optimism: {
      url: `https://opt-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
      chainId: 10,
      accounts: PK ? [PK] : [],
    },
    rinkeby: {
      accounts: PK ? [PK] : [],
      chainId: 4,
      url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    ropsten: {
      accounts: PK ? [PK] : [],
      chainId: 3,
      url: `https://eth-ropsten.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
  },

  solidity: {
    compilers: [
      {
        version: "0.8.14",
      },
    ],
  },

  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },

  verify: {
    etherscan: {
      apiKey: ETHERSCAN_API,
    },
  },
};

export default config;
