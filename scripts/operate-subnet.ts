import { ethers, upgrades } from 'hardhat';
const networkContract = '0x7b45C5Bf6b4f27E9ac0F9a6907656c2BE342c16F'; // testnet
const tokenContract = '0xEdC160695971977326Ff10f285a6cd7dA6B2186c'; // testnet
const x_tokenContract = '0xBf58C54DA1c778D3f77c47332C1554bda1D95ea0'; // testnet
const sentryContract = '0x9856c3B8d03937862C57b2330aF088684CA196c1'; // testnet
const validatorContract = '0x58E549288E64e4A1bcF80aeCfa3bb002E6C4742b'; // testnet

const contractAddress = '0x331bd4973dAC41F20aAB98856bB2cF3b691419a6'; //testnet

async function main() {
  const [owner, otherAccount] = await ethers.getSigners();

  const Subnet = await ethers.getContractFactory('Subnet');
  const subnet = Subnet.attach(contractAddress);

  const XToken = await ethers.getContractFactory('xMLTToken');
  const xToken = XToken.attach(x_tokenContract);
  await xToken.setMinter(subnet.target);

  // const Token = await ethers.getContractFactory('IcmToken');
  // const _token = await Token.attach(TOKEN_ADDRESS);
  // const approve = await _token.approve(STAKE_ADDRESS, '2500');
  // await approve.wait();
  // const _stake = await Stake.attach(STAKE_ADDRESS);
  // await _stake.stake('2500');
  // console.log('Operate on : ', _stake.address);
  // return { _stake, owner, otherAccount };
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
