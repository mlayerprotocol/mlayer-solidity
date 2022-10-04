import { ethers, upgrades } from "hardhat";

async function main() {

  const [owner, otherAccount] = await ethers.getSigners();
  const TOKEN_ADDRESS = "0xdA8b9F796676Bd2E3aC47bE5a0EdB507d17B632a";
  const Stake = await ethers.getContractFactory("Stake");
  const _stake = await upgrades.deployProxy(
    Stake,
    [
      TOKEN_ADDRESS
    ],
    {
      initializer: 'initialize',
    }
  );
  console.log('Stake Deployed to : ', _stake.address)
  return { _stake, owner, otherAccount };
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
