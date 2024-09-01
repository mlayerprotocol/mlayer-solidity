import { ethers, upgrades } from "hardhat";

async function main() {
  const contractAddress = '0x7b45C5Bf6b4f27E9ac0F9a6907656c2BE342c16F';
  const [owner, otherAccount] = await ethers.getSigners();
  const TOKEN_ADDRESS = '0xdA8b9F796676Bd2E3aC47bE5a0EdB507d17B632a';
  const STAKE_ADDRESS = '0x5AD1A7a5432520038eB37c673f8a1AbA774D1e6c';

  const Contract = await ethers.getContractFactory('Network');
  // const Token = await ethers.getContractFactory('IcmToken');
  // const _token = await Token.attach(TOKEN_ADDRESS);
  // const approve = await _token.approve(STAKE_ADDRESS, '2500');
  // await approve.wait();
  const contract = Contract.attach(contractAddress);

  const d = await contract.authorize();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
