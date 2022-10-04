import { ethers, upgrades } from "hardhat";

async function main() {

  const [owner, otherAccount] = await ethers.getSigners();
  const STAKE_ADDRESS = "0x5AD1A7a5432520038eB37c673f8a1AbA774D1e6c";
  const Stake = await ethers.getContractFactory("Stake");
  const _stake = await upgrades.upgradeProxy(
    STAKE_ADDRESS, Stake
  );
  console.log('Stake Upgrade on : ', _stake.address)
  return { _stake, owner, otherAccount };
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
