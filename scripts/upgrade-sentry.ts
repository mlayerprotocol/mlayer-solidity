import { ethers, upgrades } from 'hardhat';

const contractAddress = '0x9856c3B8d03937862C57b2330aF088684CA196c1';

async function main() {
  const [owner, otherAccount] = await ethers.getSigners();
  const Contract = await ethers.getContractFactory('SentryNode');
  const contract = await upgrades.upgradeProxy(contractAddress, Contract);
  console.log('Sentry Deployed to : ', contract.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
