import { ethers, upgrades } from "hardhat";

async function main() {

  const [owner, otherAccount] = await ethers.getSigners();
  const TOKEN_ADDRESS = "0xdA8b9F796676Bd2E3aC47bE5a0EdB507d17B632a";
  const STAKE_ADDRESS = "0x5AD1A7a5432520038eB37c673f8a1AbA774D1e6c";
  const Stake = await ethers.getContractFactory("Stake");
  const Token = await ethers.getContractFactory("IcmToken");
  const _token = await Token.attach(
    TOKEN_ADDRESS
  );
  await _token.approve(STAKE_ADDRESS, '100')
  const _stake = await Stake.attach(
    STAKE_ADDRESS
  );
  await _stake.stake('100');
  console.log('Operate on : ', _stake.address)
  return { _stake, owner, otherAccount };
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
