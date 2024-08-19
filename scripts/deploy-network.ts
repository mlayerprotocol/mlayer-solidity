import { ethers, upgrades } from 'hardhat';

async function main() {
  const [owner, otherAccount] = await ethers.getSigners();
  const Contract = await ethers.getContractFactory('Network');
  const network = await upgrades.deployProxy(Contract, [2n, 0n], {
    initializer: 'initialize',
  });
  console.log('Network Deployed to : ', network.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
