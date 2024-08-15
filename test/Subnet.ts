import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe('Subnet', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  let ownerAccount: any;
  async function deployContract() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();
    const IcmToken = await ethers.getContractFactory('IcmToken');
    const _icmToken = await IcmToken.deploy();

    const xIcmToken = await ethers.getContractFactory('xMLTToken');
    const _xToken = await xIcmToken.deploy();

    const Subnet = await ethers.getContractFactory('Subnet');
    const _subnet = await Subnet.deploy();

    await _subnet.initialize(
      _icmToken.getAddress(),
      _xToken.getAddress(),
      owner.address,
      owner.address
    );

    return { _icmToken, xIcmToken, _subnet, owner, otherAccount };
  }

  describe('Deployment', function () {
    it('Should have withdrawalEnabled as FALSE', async function () {
      const { _subnet, owner } = await loadFixture(deployContract);
      ownerAccount = owner;
      expect(await _subnet.withdrawalEnabled()).to.equal(false);
    });
  });

  describe('Staking...', function () {
    const subnet = '193430c8-7927-2d6d-c293-27d03420ca0c';
    const subnetHex = `0x${subnet.replaceAll('-', '')}`;
    const subnetAmountVal = 2000;
    const subnetAmountVal2: bigint = BigInt(6000 * 10 ** 18);
    it(`Should Subnet ${subnetHex} -- ${subnetAmountVal}`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);
      ownerAccount = owner;
      await _icmToken.approve(_subnet.getAddress(), subnetAmountVal);
      await expect(_subnet.stake(subnetHex, 0)).to.be.revertedWith(
        'You need to stake the minimum amount of tokens'
      );
      await expect(
        _subnet.stake(subnetHex, subnetAmountVal)
      ).to.be.revertedWith('You need to stake more than the minimum stake');
      await _icmToken.approve(_subnet.getAddress(), subnetAmountVal2);
      await expect(_subnet.stake(subnetHex, subnetAmountVal2)).not.to.be
        .reverted;

      expect(await _subnet.subnetBalance(subnetHex)).to.equal(subnetAmountVal2);
    });
  });

  describe('Get Balance...', function () {
    const subnet = '193430c8-7927-2d6d-c293-27d03420ca0c';
    const subnetHex = `0x${subnet.replaceAll('-', '')}`;
    const subnetAmountVal: bigint = BigInt(6000 * 10 ** 18);
    // const minStakable = 5000 * 10**18;
    const minStakable: bigint = BigInt(5000 * 10 ** 18);
    it(`Should Get Balance for Subnet ${subnetHex} -- ${subnetAmountVal} == ${minStakable}`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);

      await _icmToken.approve(_subnet.getAddress(), subnetAmountVal);
      expect(await _subnet.minStakable()).to.equal(minStakable);
      await _subnet.stake(subnetHex, subnetAmountVal);
      expect(await _subnet.subnetBalance(subnetHex)).to.equal(subnetAmountVal);

      expect(await _subnet.subnetBalance(subnetHex)).to.equal(subnetAmountVal);
    });
  });

  describe('Hash functions should return valid hash ...', function () {
    const claimHash =
      '0x9f6228cebed09409140930abb1a724654ef60f44bafd6d13652628770181a69a';
    const dataHash =
      '0x85b97b0781894acf2501df97c7824d4376b39fe533fa295a5183b06e15c2106e';

    const claim = {
      claimData: [
        { subnetId: '0x3fafe8ae9a4fc926476f4a62c47c0d88', amount: '3' },
        { subnetId: '0x8c85a7bf072f68d207849513cde56d26', amount: '3' },
        { subnetId: '0xe5b7c3c49041a3f65d1c06a8a61c75c8', amount: '2' },
      ],
      cycle: 197,
      index: 0,
      totalCost: 8,
      validator:
        '0x03d212263468365e70b2d673b06b903216b5e101d8243cdbfac6884369e3c069a0',
      signers: [
        {
          x: '52123358070701148306622828176892746455368469023786539685348457208293984548291',
          y: '92172503405036832815560669856669622701605492012293878430727530194193853824392',
        },
      ],
      commitment: '0xdb74db34d50674eba3a6128f2a90133be58b8aff',
      signature:
        '0x501dc8049bf11471b4ae3de77e10f8bef394db836fb0f3d2ed4f86a7f31b7e15',
    };

    it(`hashRewardData should return valid hash`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);

      expect(await _subnet.hashRewardData(claim.claimData)).to.equal(dataHash);
    });

    it(`getClaimHash should return valid hash`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);

      expect(await _subnet.getClaimHash(claim)).to.equal(claimHash);
    });

    it(`verifyClaim should be true`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);
      const verify = await _subnet.verifyClaim(claim);
      console.log('Verifying...', verify);
      expect(verify[0]).to.equal(true);
    });
  });

  // describe("Unstack...", function () {
  //   const subnetId = "001";
  //   const subnetAmountVal: bigint = BigInt(6000 * 10 ** 18);

  //   const minStakable: bigint = BigInt(5000 * 10 ** 18);
  //   it(`Should Get Unstack`, async function () {
  //     const { _subnet, _icmToken, owner } = await loadFixture(deployContract);

  //     await _icmToken.approve(_subnet.getAddress(), subnetAmountVal);

  //     await _subnet.stake(subnetId, subnetAmountVal);

  //     await expect(_subnet.unStake(subnetId)).to.be.revertedWith(
  //       "Withdrawal is not enabled"
  //     );
  //     await _subnet.enableWithdrawal(true);
  //     await expect(_subnet.unStake(subnetId)).to.not.be.revertedWith(
  //       "Withdrawal is not enabled"
  //     );
  //   });
  // });
});
