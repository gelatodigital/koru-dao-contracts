import hre = require("hardhat");
const { ethers } = hre;
import { relayV0Send } from "../hardhat/utils/relayV0";
import { KoruDaoRelayTransit } from "../typechain";

const main = async () => {
  const koruDaoRelayTransit = <KoruDaoRelayTransit>(
    await ethers.getContract("KoruDaoRelayTransit")
  );

  const [user] = await ethers.getSigners();
  const userAddress = await user.getAddress();
  console.log("userAddress: ", userAddress);

  const chainId = Number(await hre.getChainId());

  const domain = {
    name: "KoruDaoRelayTransit",
    version: "1",
    chainId: chainId,
    verifyingContract: koruDaoRelayTransit.address,
  };

  const mintType = [
    {
      name: "user",
      type: "address",
    },
    { name: "nonce", type: "uint256" },
    {
      name: "deadline",
      type: "uint256",
    },
  ];

  const type = { Mint: mintType };

  const deadline = (await ethers.provider.getBlock("latest")).timestamp + 300;
  const nonce = await koruDaoRelayTransit.nonces(userAddress);

  const message = {
    user: userAddress,
    nonce,
    deadline,
  };

  const signature = await user._signTypedData(domain, type, message);

  const r = "0x" + signature.substring(2, 66);
  const s = "0x" + signature.substring(66, 130);
  const vStr = signature.substring(130, 132);
  const v = parseInt(vStr, 16);

  const sig = { v, r, s, deadline };

  const fee = ethers.utils.parseEther("0.05"); // TODO: add estimations?
  const data = koruDaoRelayTransit.interface.encodeFunctionData("mint", [
    userAddress,
    fee,
    sig,
  ]);

  await relayV0Send(
    chainId,
    koruDaoRelayTransit.address,
    data,
    fee.toString(),
    10_000_000
  );
};

main();
