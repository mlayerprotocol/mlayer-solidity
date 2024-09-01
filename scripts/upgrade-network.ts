import { ethers, upgrades } from 'hardhat';

const contractAddress = '0x7b45C5Bf6b4f27E9ac0F9a6907656c2BE342c16F';

async function main() {
  const [owner, otherAccount] = await ethers.getSigners();
  const Contract = await ethers.getContractFactory('Network');
  const network = await upgrades.upgradeProxy(contractAddress, Contract);
  console.log('Network Deployed to : ', network.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
