import { ethers, upgrades } from 'hardhat';

const contractAddress = '0x58E549288E64e4A1bcF80aeCfa3bb002E6C4742b';

async function main() {
  const [owner, otherAccount] = await ethers.getSigners();
  const Contract = await ethers.getContractFactory('SentryNode');
  const contract = await upgrades.upgradeProxy(contractAddress, Contract);
  console.log('Validator Deployed to : ', contract.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
