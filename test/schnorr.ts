import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Stake', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Schnorr = await ethers.getContractFactory('LibSchnorrTest');
    const schnorr = await Schnorr.deploy();

    return { schnorr, owner, otherAccount };
  }

  describe('Deployment', function () {
    // it('Should verify signature', async function () {
    //   const { schnorr } = await loadFixture(deployOneYearLockFixture);
    //   const hash = ethers.utils.keccak256(Buffer.from('femi'));
    //   const seed = ethers.utils.randomBytes(16);

    //   console.log(
    //     'Verify',
    //     await schnorr.testFuzz_verifySignature_SingleSigner(seed, hash)
    //   );
    //   expect(
    //     await schnorr.testFuzz_verifySignature_SingleSigner(seed, hash)
    //   ).to.equal(true);
    // });

    it('Should verify multiple aggregate signatures', async function () {
      const { schnorr } = await loadFixture(deployOneYearLockFixture);
      const hash = ethers.utils.keccak256(Buffer.from('femi'));
      const seed = ethers.utils.randomBytes(16);
      console.log(
        'SEEED',
        Buffer.from(seed.buffer, seed.byteOffset, seed.byteLength).toString(
          'hex'
        )
      );
      const wallet = ethers.Wallet.createRandom();
      // wallet.publicKey.console.log('SEEED', seed);
      const seeds = [
        Buffer.from('2f04020b9c71fdb501d5ce30b99b85f7', 'hex'),
        Buffer.from('5da1ab48fa824aa7daa68547abfaadad', 'hex'),
      ];
      // for (let i = 0; i < 2; i++) {
      //   seeds.push(seed);
      // }
      // console.log('Verifying seeds', seeds);
      expect(
        await schnorr.testFuzz_verifySignature_MultipleSigners(seeds, hash)
      ).to.equal(true);
    });
  });
});
