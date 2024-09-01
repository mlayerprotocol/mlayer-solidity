import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { ContractTransactionResponse } from 'ethers';
import {
  IcmToken,
  .targe,
  XMLTToken,
  Subnet,
  Network,
  NodeLicense,
} from '../typechain-types';
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers';

let networkContract: Network & {
  deploymentTransaction(): ContractTransactionResponse;
};
let sentryContract: .targe & {
  deploymentTransaction(): ContractTransactionResponse;
};
let icmTokenContract: IcmToken & {
  deploymentTransaction(): ContractTransactionResponse;
};
let xTokenContract: XMLTToken & {
  deploymentTransaction(): ContractTransactionResponse;
};
let validatorContract: .targe & {
  deploymentTransaction(): ContractTransactionResponse;
};
let subnetContract: Subnet & {
  deploymentTransaction(): ContractTransactionResponse;
};
let sentryLicenseContract: NodeLicense & {
  deploymentTransaction(): ContractTransactionResponse;
};
let validatorLicenseContract: NodeLicense & {
  deploymentTransaction(): ContractTransactionResponse;
};
let ownerAccount: HardhatEthersSigner;
let otherAccount: HardhatEthersSigner;

describe('Subnet', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.

  async function deployContract() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, _account3, _account4] =
      await ethers.getSigners();

    const Network = await ethers.getContractFactory('Network');
    const network = await Network.deploy();
    await network.initialize(2n, 0n);

    const IcmToken = await ethers.getContractFactory('IcmToken');
    const _icmToken = await IcmToken.deploy(
      'ICM',
      'ICM',
      ethers.parseEther('1000000000')
    );

    const xIcmToken = await ethers.getContractFactory('xMLTToken');
    const xToken = await xIcmToken.deploy(
      'xICM',
      'xICM',
      ethers.parseEther('1000000000')
    );

    const LicenseContract = await ethers.getContractFactory('NodeLicense');
    const _licenseContract = await LicenseContract.deploy();
    _licenseContract.initialize(
      'LicenceContract',
      'MLL',
      otherAccount.address,
      [
        { price: ethers.parseEther('0.0001'), quantity: 5 },
        { price: ethers.parseEther('0.0002'), quantity: 5 },
        { price: ethers.parseEther('0.0003'), quantity: 5 },
      ]
    );

    _licenseContract.addPromoCode('ML', _account3.address);
    _licenseContract.setPromoPercentages(5n, 5n);

    const ValLicenseContract = await ethers.getContractFactory('NodeLicense');
    const _valLicenseContract = await LicenseContract.deploy();
    _valLicenseContract.initialize(
      'ValLicenceContract',
      'vMLL',
      _account4.address,
      [
        { price: ethers.parseEther('0.0005'), quantity: 5 },
        { price: ethers.parseEther('0.0010'), quantity: 5 },
        { price: ethers.parseEther('0.0015'), quantity: 5 },
      ]
    );

    _valLicenseContract.addPromoCode('ML', _account3.address);
    _valLicenseContract.setPromoPercentages(5n, 5n);

    const Sentry = await ethers.getContractFactory('.targe');
    const sentry = await Sentry.deploy();
    await sentry.initialize(
      network.target,
      _icmToken.target,
      _licenseContract.target
    );
    await _licenseContract.setNodeContract(sentry.target);

    console.log('CURRENTBLOCK:::', await network.getCurrentBlockNumber());
    const Validator = await ethers.getContractFactory('.targe');
    const validator = await Validator.deploy();
    await validator.initialize(
      network.target,
      _icmToken.target,
      _valLicenseContract.target
    );
    await _valLicenseContract.setNodeContract(validator.target);

    const Subnet = await ethers.getContractFactory('Subnet');
    const _subnet = await Subnet.deploy();

    await _subnet.initialize(
      network.target,
      _icmToken.target,
      xToken.target,
      sentry.target,
      validator.target
    );
    await xToken.setMinter(_subnet.target);
    return {
      _icmToken,
      xToken,
      sentry,
      validator,
      _subnet,
      _valLicenseContract,
      _licenseContract,
      owner,
      otherAccount,
    };
  }

  describe('Deployment', function () {
    it('Should have withdrawalEnabled as FALSE', async function () {
      const {
        _subnet,
        owner,
        _icmToken,
        xToken,
        sentry,
        _licenseContract,
        _valLicenseContract,
        validator,
      } = await loadFixture(deployContract);
      ownerAccount = owner;
      sentryContract = sentry;
      icmTokenContract = _icmToken;
      xTokenContract = xToken;
      validatorContract = validator;
      subnetContract = _subnet;
      sentryLicenseContract = _licenseContract;
      validatorLicenseContract = _valLicenseContract;

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
      await _icmToken.approve(_subnet.target, subnetAmountVal);
      await expect(_subnet.stake(subnetHex, 0)).to.be.revertedWith(
        'You need to stake the minimum amount of tokens'
      );
      await expect(
        _subnet.stake(subnetHex, subnetAmountVal)
      ).to.be.revertedWith('You need to stake more than the minimum stake');
      await _icmToken.approve(_subnet.target, subnetAmountVal2);
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

      await _icmToken.approve(_subnet.target, subnetAmountVal);
      expect(await _subnet.minStakable()).to.equal(minStakable);
      await _subnet.stake(subnetHex, subnetAmountVal);
      expect(await _subnet.subnetBalance(subnetHex)).to.equal(subnetAmountVal);

      expect(await _subnet.subnetBalance(subnetHex)).to.equal(subnetAmountVal);
    });
  });

  describe('Rewards ...', function () {
    const claimHash =
      '0x206d50a86bdb86bb83d707478cf251d973fdc7686e813d1dd7ea63d6929bd1e9';
    const dataHash =
      '0x6e35fb5d5519f0b4fbcfb6b8f0cb4ef1ceb1cfb11d1d36f8ebaca72c4b438cb1';
    let claimData = [
      { subnetId: '0x3fafe8ae9a4fc926476f4a62c47c0d88', amount: '30000000' },
      { subnetId: '0x8c85a7bf072f68d207849513cde56d26', amount: '30000000' },
      { subnetId: '0xe5b7c3c49041a3f65d1c06a8a61c75c8', amount: '20000000' },
    ];
    // for (let i = 0; i <= 100; i++) {
    //   claimData = claimData.concat([
    //     { subnetId: '0x3fafe8ae9a4fc926476f4a62c47c0d88', amount: '3' },
    //     { subnetId: '0x8c85a7bf072f68d207849513cde56d26', amount: '3' },
    //     { subnetId: '0xe5b7c3c49041a3f65d1c06a8a61c75c8', amount: '2' },
    //   ]);
    // }
    let signers = [
      {
        x: '52123358070701148306622828176892746455368469023786539685348457208293984548291',
        y: '92172503405036832815560669856669622701605492012293878430727530194193853824392',
      },
    ];
    // for (let i = 0; i <= 100; i++) {
    //   signers = signers.concat([
    //     {
    //       x: '52123358070701148306622828176892746455368469023786539685348457208293984548291',
    //       y: '92172503405036832815560669856669622701605492012293878430727530194193853824392',
    //     },
    //   ]);
    // }
    const regData = {
      signature:
        '0x75e8bfce322bfcf06a37f8a0ba2a19d850d5a80023f2a56f64fd282207890cdc',
      publicKey:
        '0x02733cc67380d6a8f4dad591126e08bd4d8f4471de0cc611f8cbc05461a85fb5c3',
      nonce: 1723776438802n,
      commitment: '0xdbbf3d1bfc7839f0e25db4e61034228f2fb4550b',
    } as any;

    const claim = {
      claimData: claimData,
      cycle: 0,
      index: 0,
      totalCost: '80000000',
      validator:
        '0x03d212263468365e70b2d673b06b903216b5e101d8243cdbfac6884369e3c069a0',
      signers: signers,
      commitment: '0x8b903d1011e877092ad7216e2aaf9195a6932122',
      signature:
        '0x183631230407b83b0eb92d88c487becb6e8eb231d6a7d35263710b2d753ed23e',
    };

    it(`hashRewardData should return valid hash for length ${claimData.length} and ${signers.length}`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);

      expect(await _subnet.hashRewardData(claim.claimData)).to.equal(dataHash);
    });

    it(`getClaimHash should return valid hash for length ${claimData.length} and ${signers.length}`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);

      expect(await _subnet.getClaimHash(claim)).to.equal(claimHash);
    });

    it(`verifyClaim should be true`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);
      const verify = await _subnet.verifyClaim(claim);
      console.log('Verifying...', verify);
      expect(verify[0]).to.equal(true);
    });

    it('Should be able to make purchase', async function () {
      // const { _sentryContract, owner } = await loadFixture(deployContract);
      const promoCode = '';
      const quantity = 4n;
      const licenseCost = await sentryLicenseContract.licensePrice(
        quantity,
        promoCode
      );

      // await icmTokenContract.approve(
      //   ownerAccount.address,
      //   licenseCost * quantity
      // );
      const [_owner, _otherAccount, _account3, _account4] =
        await ethers.getSigners();
      const balanceBefore = await ethers.provider.getBalance(
        _otherAccount.address
      );
      await expect(
        sentryContract.purchaseLicense(quantity, promoCode, {
          value: licenseCost,
        })
      ).to.not.be.reverted;

      const balance = await ethers.provider.getBalance(_otherAccount.address);

      expect(balance).to.equal(balanceBefore + licenseCost);
    });

    it('Should be able to registerNodeOperator', async function () {
      // const { _sentryContract, _icmToken, owner, otherAccount } =
      //   await loadFixture(deployContract);
      await expect(
        sentryContract.registerNodeOperator(regData, [1006n])
      ).to.be.revertedWith('registerNodeOperator: you must own all licenses');

      await expect(sentryContract.registerNodeOperator(regData, [1n, 2n])).to
        .not.be.reverted;
    });

    it(`rewardValidator should be fail`, async function () {
      //  const verify = await _subnet.rewardValidator(claim);
      //  console.log('Verifying...', verify);

      await expect(subnetContract.rewardValidator(claim)).to.not.reverted;
    });
  });

  // describe("Unstack...", function () {
  //   const subnetId = "001";
  //   const subnetAmountVal: bigint = BigInt(6000 * 10 ** 18);

  //   const minStakable: bigint = BigInt(5000 * 10 ** 18);
  //   it(`Should Get Unstack`, async function () {
  //     const { _subnet, _icmToken, owner } = await loadFixture(deployContract);

  //     await _icmToken.approve(_subnet.target, subnetAmountVal);

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
