/* eslint-disable @typescript-eslint/no-explicit-any */
import { Signer } from "@ethersproject/abstract-signer";
import { expect } from "chai";
import hre = require("hardhat");
const { ethers, deployments } = hre;
import {} from "../typechain";

describe("Ops Time module test", function () {
  this.timeout(0);
  let user: Signer;
  let userAddress: string;

  beforeEach(async function () {
    await deployments.fixture();
    [, user] = await ethers.getSigners();
    userAddress = await user.getAddress();
  });
});
