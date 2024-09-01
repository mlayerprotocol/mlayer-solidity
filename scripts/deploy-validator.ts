import { ethers, upgrades } from 'hardhat';

const networkContract = '0x7b45C5Bf6b4f27E9ac0F9a6907656c2BE342c16F'; // testnet
const tokenContract = '0xEdC160695971977326Ff10f285a6cd7dA6B2186c'; // testnet
const validatorLicenseContract = '0xBB25424730Ab9976B69E622eC13E061E52b32210'; //testnet

async function main() {
  const [owner, otherAccount] = await ethers.getSigners();
  const Contract = await ethers.getContractFactory('SentryNode');
  const contract = await upgrades.deployProxy(
    Contract,
    [networkContract, tokenContract, validatorLicenseContract],
    {
      initializer: 'initialize',
    }
  );
  const LicenseContract = await ethers.getContractFactory('NodeLicense');
  const licenseContract = LicenseContract.attach(validatorLicenseContract);
  const tx = await licenseContract.setNodeContract(contract.target);
  console.log('setNodeContract Hash:', tx.hash);
  console.log('Validator Deployed to : ', contract.target);
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
