import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Network', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployContract() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Network = await ethers.getContractFactory('Network');
    const network = await Network.deploy();

    await network.initialize(2, 0);

    return { network, owner, otherAccount };
  }

  describe('Deployment', function () {
    it('Should have withdrawalEnabled as FALSE', async function () {
      const { network, owner } = await loadFixture(deployContract);
      console.log('DSDS', await network.getCurrentMessagePrice());
      expect(await network.getCurrentMessagePrice()).to.equal(
        ethers.parseEther('0.001')
      );
      const newPrice = ethers.parseEther('0.00003');
      await network.setMessagePrice(ethers.parseEther('0.00003'));
      expect(await network.getCurrentMessagePrice()).to.equal(
        ethers.parseEther('0.001')
      );
      // await expect(_stake.unStake()).to.be.revertedWith(
      //   "Withdrawal is not enabled"
      // );
    });
  });
});
