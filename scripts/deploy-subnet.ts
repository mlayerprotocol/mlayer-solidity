import { ethers, upgrades } from 'hardhat';

const networkContract = ''; // testnet
const tokenContract = ''; // testnet
const x_tokenContract = ''; // testnet
const sentryContract = ''; // testnet
const validatorContract = ''; // testnet

async function main() {
  const [owner, otherAccount] = await ethers.getSigners();
  const Contract = await ethers.getContractFactory('Subnet');
  const contract = await upgrades.deployProxy(
    Contract,
    [
      networkContract,
      tokenContract,
      x_tokenContract,
      sentryContract,
      validatorContract,
    ],
    {
      initializer: 'initialize',
    }
  );
  const XToken = await ethers.getContractFactory('xMLTToken');
  const xToken = XToken.attach(x_tokenContract);
  await xToken.setSubnetContract(contract.getAddress());
  console.log('Subnet Deployed to : ', contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
