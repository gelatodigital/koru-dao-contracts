import hre = require("hardhat");
const { ethers } = hre;
import { KoruDao } from "../typechain";

enum Action {
  POST,
  FOLLOW,
  MIRROR,
}

const main = async () => {
  const koruDao = <KoruDao>await ethers.getContract("KoruDao");
  const timeRestriction = await ethers.getContract("KoruDaoTimeRestriction");

  await koruDao.setActionRestriction(Action.POST, timeRestriction.address);
};

main();
