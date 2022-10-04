import { ethers } from "hardhat";

async function main() {
  // const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  // const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  // const unlockTime = currentTimestampInSeconds + ONE_YEAR_IN_SECS;

  // const lockedAmount = ethers.utils.parseEther("1");

  // const Lock = await ethers.getContractFactory("Lock");
  // const lock = await Lock.deploy(unlockTime, { value: lockedAmount });

  // await lock.deployed();

  const [owner, otherAccount] = await ethers.getSigners();

  const IcmToken = await ethers.getContractFactory("ERC20");
  const _icmToken = await IcmToken.deploy();

  const Stake = await ethers.getContractFactory("Stake");
  const _stake = await Stake.deploy(_icmToken.address);
  console.log(`IcmToken deployed to ${_icmToken.address}`);
  console.log(`Stake deployed to ${_stake.address}`);
  return { _icmToken, _stake, owner, otherAccount };

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
