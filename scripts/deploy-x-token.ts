import { ethers, upgrades } from 'hardhat';

const networkContract = ''; // testnet
const tokenContract = ''; // testnet

async function main() {
  const [owner, otherAccount] = await ethers.getSigners();
  const Contract = await ethers.getContractFactory('xMLTToken');
  const contract = await Contract.deploy('X_ICM', 'X_ICM', 0n);
  console.log('X_Token Deployed to : ', contract.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
