import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { IcmToken, SentryContract } from "../typechain-types";
import { ContractTransactionResponse } from "ethers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

let sentryContract: SentryContract & {
  deploymentTransaction(): ContractTransactionResponse;
};
let icmToken: IcmToken & {
  deploymentTransaction(): ContractTransactionResponse;
}


let owner: HardhatEthersSigner;
let otherAccount: HardhatEthersSigner;

describe("SentryContract", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployContract() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const IcmToken = await ethers.getContractFactory("IcmToken");
    const _icmToken = await IcmToken.deploy();

    const SentryContract = await ethers.getContractFactory("SentryContract");
    const _sentryContract = await SentryContract.deploy();

    await _sentryContract.initialize(_icmToken.getAddress());

    return { _icmToken, _sentryContract, owner, otherAccount };
  }

  describe("Get Licence Price", function () {
    it("Should have licensePrice be startNodePrice ", async function () {
      const {
        _sentryContract,
        _icmToken,
        owner: _owner,
        otherAccount: _otherAccount,
      } = await loadFixture(deployContract);
      sentryContract = _sentryContract;
      owner = _owner;
      otherAccount = _otherAccount;
      icmToken = _icmToken;
      const licensePrice = await _sentryContract.getLicencePrice();
      const startNodePrice = await _sentryContract.startNodePrice();
      expect(licensePrice).to.equal(startNodePrice);
    });
  });

  describe("Purchase Licence", function () {
    it("Should be able to make purchase", async function () {
      // const { _sentryContract, owner } = await loadFixture(deployContract);
      const quantity = 1n;
      const licenseCost = (await sentryContract.getLicencePrice()) * quantity;

      await expect(
        sentryContract.purchaseLicense(quantity, { value: licenseCost })
      ).to.not.be.reverted;
      const contractBalance = await ethers.provider.getBalance(
        sentryContract.getAddress()
      );

      expect(contractBalance).to.equal(licenseCost);
    });
  });

  describe("withdrawEthers", function () {
    it("Should be able to withdraw Ethers", async function () {
      // const { _sentryContract, owner, otherAccount } = await loadFixture(
      //   deployContract
      // );
      const quantity = 1n;
      const licenseCost = (await sentryContract.getLicencePrice()) * quantity;
      const ownerAccountBalanceBefore = await ethers.provider.getBalance(
        owner.getAddress()
      );
      const otherAccountBalanceBefore = await ethers.provider.getBalance(
        otherAccount.getAddress()
      );

      await expect(
        sentryContract.purchaseLicense(quantity, { value: licenseCost })
      ).to.not.be.reverted;
      const contractBalance = await ethers.provider.getBalance(
        sentryContract.getAddress()
      );

      await expect(sentryContract.withdrawEthers(otherAccount)).to.not.be
        .reverted;

      const otherAccountBalanceAfter = await ethers.provider.getBalance(
        otherAccount.getAddress()
      );

      expect(otherAccountBalanceAfter).to.equal(
        contractBalance + otherAccountBalanceBefore
      );
    });
  });

  describe("withdraw Non Ethers", function () {
    it("Should be able to withdraw non Ethers", async function () {
      // const { _sentryContract, _icmToken, owner, otherAccount } =
      //   await loadFixture(deployContract);
      const quantity = 1n;
      const licenseCost = (await sentryContract.getLicencePrice()) * quantity;
      const otherAccountBalanceBefore = await ethers.provider.getBalance(
        otherAccount.getAddress()
      );
      console.log(
        "Before--",
        { licenseCost },
        await icmToken.balanceOf(owner),
        await icmToken.balanceOf(sentryContract.getAddress())
      );
      await expect(
        icmToken.transfer(sentryContract.getAddress(), licenseCost)
      ).to.not.be.reverted;

      expect(await icmToken.balanceOf(sentryContract.getAddress())).to.equal(
        licenseCost
      );

      await expect(
        sentryContract.withdraw(
          icmToken.getAddress(),
          otherAccount,
          licenseCost
        )
      ).to.not.be.reverted;

      expect(await icmToken.balanceOf(sentryContract.getAddress())).to.equal(
        0n
      );
    });
  });

  describe('testSignatureVerification', function () {
    it('Should verify Single SIgner', async function () {
      expect(
        await sentryContract.verifySingleSigner(
          {
            signature:
              '0x62939200d699ca0c0d4d66bdaa23f9d84ef1d18a140996664ff8b1cb62086d76',
            publicKey:
              '0x03d212263468365e70b2d673b06b903216b5e101d8243cdbfac6884369e3c069a0',
            nonce: 1721333362786,
            commitment: '0x0d68c54d51320d127586a649aa3b18d71b921f77',
          } as any,
          '0x150823c524d0fc7086d30f9dad5aaf0a0845d25e0b98f0da2eb51e682c2acb10'
        )
      ).to.be.equal(true);
    });
  });
  describe('registerNodeOperator', function () {
    it('Should be able to registerNodeOperator', async function () {
      // const { _sentryContract, _icmToken, owner, otherAccount } =
      //   await loadFixture(deployContract);

      await expect(
        sentryContract.registerNodeOperator(
          {
            signature:
              '0x62939200d699ca0c0d4d66bdaa23f9d84ef1d18a140996664ff8b1cb62086d76',
            publicKey:
              '0x03d212263468365e70b2d673b06b903216b5e101d8243cdbfac6884369e3c069a0',
            nonce: 1721333362786,
            commitment: '0x0d68c54d51320d127586a649aa3b18d71b921f77',
          } as any,
          [2n]
        )
      ).to.be.revertedWith(
        'Sentry/registerNodeAccount: you must own all licences'
      );
      await expect(
        sentryContract.registerNodeOperator(
          {
            signature:
              '0x62939200d699ca0c0d4d66bdaa23f9d84ef1d18a140996664ff8b1cb62086d76',
            publicKey:
              '0x03d212263468365e70b2d673b06b903216b5e101d8243cdbfac6884369e3c069a0',
            nonce: 1721333362786,
            commitment: '0x0d68c54d51320d127586a649aa3b18d71b921f77',
          } as any,
          [1000n]
        )
      ).to.not.be.reverted;
    });
  });

  // describe("Staking...", function () {
  //   const subnet = "193430c8-7927-2d6d-c293-27d03420ca0c";
  //   const subnetHex = `0x${subnet.replaceAll("-", "")}`;
  //   const subnetAmountVal = 2000;
  //   const subnetAmountVal2: bigint = BigInt(6000 * 10 ** 18);
  //   it(`Should SentryContract ${subnetHex} -- ${subnetAmountVal}`, async function () {
  //     const { _sentryContract, _icmToken, owner } = await loadFixture(deployContract);

  //     await _icmToken.approve(_sentryContract.getAddress(), subnetAmountVal);
  //     await expect(_sentryContract.stake(subnetHex, 0)).to.be.revertedWith(
  //       "You need to stake the minimum amount of tokens"
  //     );
  //     await expect(
  //       _sentryContract.stake(subnetHex, subnetAmountVal)
  //     ).to.be.revertedWith("You need to stake more than the minimum stake");
  //     await _icmToken.approve(_sentryContract.getAddress(), subnetAmountVal2);
  //     await expect(_sentryContract.stake(subnetHex, subnetAmountVal2)).not.to.be
  //       .reverted;

  //     expect(await _sentryContract.subnetBalance(subnetHex)).to.equal(subnetAmountVal2);
  //   });
  // });

  // describe("Get Balance...", function () {
  //   const subnet = "193430c8-7927-2d6d-c293-27d03420ca0c";
  //   const subnetHex = `0x${subnet.replaceAll("-", "")}`;
  //   const subnetAmountVal: bigint = BigInt(6000 * 10 ** 18);
  //   // const minStakable = 5000 * 10**18;
  //   const minStakable: bigint = BigInt(5000 * 10 ** 18);
  //   it(`Should Get Balance for SentryContract ${subnetHex} -- ${subnetAmountVal} == ${minStakable}`, async function () {
  //     const { _sentryContract, _icmToken, owner } = await loadFixture(deployContract);

  //     await _icmToken.approve(_sentryContract.getAddress(), subnetAmountVal);
  //     expect(await _sentryContract.minStakable()).to.equal(minStakable);
  //     await _sentryContract.stake(subnetHex, subnetAmountVal);
  //     expect(await _sentryContract.getSentryContractBalance(subnetHex)).to.equal(
  //       subnetAmountVal
  //     );

  //     expect(
  //       await _sentryContract.getSentryContractAccountBalance(subnetHex, owner.getAddress())
  //     ).to.equal(subnetAmountVal);
  //   });
  // });
});
