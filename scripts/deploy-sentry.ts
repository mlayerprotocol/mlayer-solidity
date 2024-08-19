import { ethers, upgrades } from 'hardhat';

const networkContract = ''; // testnet
const tokenContract = ''; // testnet
const licensePrice = 100n; // testnet

async function main() {
  const [owner, otherAccount] = await ethers.getSigners();
  const Contract = await ethers.getContractFactory('SentryV2Node');
  const contract = await upgrades.deployProxy(
    Contract,
    [networkContract, tokenContract, licensePrice],
    {
      initializer: 'initialize',
    }
  );
  console.log('Sentry Deployed to : ', contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
