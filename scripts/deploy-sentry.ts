import { ethers, upgrades } from 'hardhat';

const networkContract = '0x7b45C5Bf6b4f27E9ac0F9a6907656c2BE342c16F'; // testnet
const tokenContract = '0xEdC160695971977326Ff10f285a6cd7dA6B2186c'; // testnet
const sentryLicenseContract = '0x0ed9b54EcF15dBb5110B9253269871BdC44468FE'; //testnet

async function main() {
  const [owner, otherAccount] = await ethers.getSigners();
  const Contract = await ethers.getContractFactory('SentryNode');
  const contract = await upgrades.deployProxy(
    Contract,
    [networkContract, tokenContract, sentryLicenseContract],
    {
      initializer: 'initialize',
    }
  );
  const LicenseContract = await ethers.getContractFactory('NodeLicense');
  const licenseContract = LicenseContract.attach(sentryLicenseContract);
  const tx = await licenseContract.setNodeContract(contract.target);
  console.log('setNodeContract Hash:', tx.hash);
  console.log('Sentry Deployed to : ', contract.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
