import { ethers, upgrades } from 'hardhat';
const contractAddress = '0x58E549288E64e4A1bcF80aeCfa3bb002E6C4742b'; // testnet

async function main() {
  const [owner, otherAccount] = await ethers.getSigners();

  const Contract = await ethers.getContractFactory('SentryNode');
  // const Token = await ethers.getContractFactory('IcmToken');
  // const _token = await Token.attach(TOKEN_ADDRESS);
  // const approve = await _token.approve(STAKE_ADDRESS, '2500');
  // await approve.wait();
  const contract = Contract.attach(contractAddress);

  const d = await contract.authorizeAdmin();
  console.log('DDDDD', d.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
