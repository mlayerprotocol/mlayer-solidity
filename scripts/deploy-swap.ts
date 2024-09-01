import { ethers, upgrades } from 'hardhat';

const tokenContract = '0xEdC160695971977326Ff10f285a6cd7dA6B2186c'; // testnet
const x_tokenContract = '0xBf58C54DA1c778D3f77c47332C1554bda1D95ea0'; // testnet

const swapContract = '0xe34faEaE5E99AeF7e7ef36261C3F1F13C7f11414';

async function main() {
  const [owner, otherAccount] = await ethers.getSigners();
  const Contract = await ethers.getContractFactory('Swap');
  const contract = await upgrades.deployProxy(
    Contract,
    [tokenContract, x_tokenContract],
    {
      initializer: 'initialize',
    }
  );
  console.log('Swap Deployed to : ', contract.target);
  const Token = await ethers.getContractFactory('IcmToken');
  const token = Token.attach(tokenContract);
  console.log((await token.setMinter(contract.target)).hash);

  const XToken = await ethers.getContractFactory('xMLTToken');
  const xToken = XToken.attach(x_tokenContract);
  console.log((await xToken.setMinter(contract.target)).hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
