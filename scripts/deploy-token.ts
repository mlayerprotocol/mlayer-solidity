import { ethers } from "hardhat";

async function main() {
  

  const [owner, otherAccount] = await ethers.getSigners();

  const IcmToken = await ethers.getContractFactory("IcmToken");
  const _icmToken = await IcmToken.deploy();
  console.log('Token Deployed to : ', _icmToken.address)

  return { _icmToken, owner, otherAccount };

  // console.log(
  //   `Lock with 1 ETH and unlock timestamp ${unlockTime} deployed to ${lock.address}`
  // );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
