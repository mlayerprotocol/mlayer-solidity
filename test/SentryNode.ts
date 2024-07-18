import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

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
      const { _sentryContract } = await loadFixture(deployContract);
      const licensePrice = await _sentryContract.getLicencePrice();
      const startNodePrice = await _sentryContract.startNodePrice();
      expect(licensePrice).to.equal(startNodePrice);
    });
  });

  describe("Purchase Licence", function () {
    it("Should be able to make purchase", async function () {
      const { _sentryContract, owner } = await loadFixture(deployContract);
      const quantity = 1n;
      const licenseCost = (await _sentryContract.getLicencePrice()) * quantity;

      await expect(
        _sentryContract.purchaseLicense(quantity, { value: licenseCost })
      ).to.not.be.reverted;
      const contractBalance = await ethers.provider.getBalance(
        _sentryContract.getAddress()
      );

      expect(contractBalance).to.equal(licenseCost);
    });
  });

  describe("withdrawEthers", function () {
    it("Should be able to withdraw Ethers", async function () {
      const { _sentryContract, owner, otherAccount } = await loadFixture(
        deployContract
      );
      const quantity = 1n;
      const licenseCost = (await _sentryContract.getLicencePrice()) * quantity;
      const otherAccountBalanceBefore = await ethers.provider.getBalance(
        otherAccount.getAddress()
      );

      await expect(
        _sentryContract.purchaseLicense(quantity, { value: licenseCost })
      ).to.not.be.reverted;
      const contractBalance = await ethers.provider.getBalance(
        _sentryContract.getAddress()
      );

      await expect(_sentryContract.withdrawEthers(otherAccount)).to.not.be
        .reverted;

      const otherAccountBalanceAfter = await ethers.provider.getBalance(
        otherAccount.getAddress()
      );
      expect(otherAccountBalanceAfter).to.equal(
        licenseCost + otherAccountBalanceBefore
      );
    });
  });

  describe("withdraw Non Ethers", function () {
    it("Should be able to withdraw non Ethers", async function () {
      const { _sentryContract, _icmToken, owner, otherAccount } =
        await loadFixture(deployContract);
      const quantity = 1n;
      const licenseCost = (await _sentryContract.getLicencePrice()) * quantity;
      const otherAccountBalanceBefore = await ethers.provider.getBalance(
        otherAccount.getAddress()
      );
      console.log(
        "Before--",
        { licenseCost },
        await _icmToken.balanceOf(owner),
        await _icmToken.balanceOf(_sentryContract.getAddress())
      );
      await expect(
        _icmToken.transfer(_sentryContract.getAddress(), licenseCost)
      ).to.not.be.reverted;

      expect(await _icmToken.balanceOf(_sentryContract.getAddress())).to.equal(
        licenseCost
      );

      await expect(
        _sentryContract.withdraw(
          _icmToken.getAddress(),
          otherAccount,
          licenseCost
        )
      ).to.not.be.reverted;

      expect(await _icmToken.balanceOf(_sentryContract.getAddress())).to.equal(
        0n
      );

      console.log(
        "AFter--",
        { licenseCost },
        await _icmToken.balanceOf(owner),
        await _icmToken.balanceOf(_sentryContract.getAddress())
      );
      const otherAccountBalanceAfter = await ethers.provider.getBalance(
        otherAccount.getAddress()
      );
      // expect(otherAccountBalanceAfter).to.equal(
      //   licenseCost + otherAccountBalanceBefore
      // );
    });
  });

  describe("registerNodeOperator", function () {
    it("Should be able to registerNodeOperator", async function () {
      const { _sentryContract, _icmToken, owner, otherAccount } =
        await loadFixture(deployContract);
      const quantity = 1n;
      const licenseCost = (await _sentryContract.getLicencePrice()) * quantity;
      const otherAccountBalanceBefore = await ethers.provider.getBalance(
        otherAccount.getAddress()
      );
      console.log(
        "Before--",
        { licenseCost },
        await _icmToken.balanceOf(owner),
        await _icmToken.balanceOf(_sentryContract.getAddress())
      );
      await expect(
        _sentryContract.registerNodeOperator(
          {
            signature:
              "0x7a5e861b67092860c46aa1174fa67f6ddb42be1a27b78d541bca3a58c9daa6d7",
            publicKey:
              "0x02c4435e768b4bae8236eeba29dd113ed607813b4dc5419d33b9294f712ca79ff4",
            nonce: 1721235365,
            commitment: "0x79f92f1a9dff6762a6e2e5a3bed57a72385770a6",
          } as any,
          [2n]
        )
      ).to.not.be.reverted;

      expect(await _icmToken.balanceOf(_sentryContract.getAddress())).to.equal(
        licenseCost
      );

      await expect(
        _sentryContract.withdraw(
          _icmToken.getAddress(),
          otherAccount,
          licenseCost
        )
      ).to.not.be.reverted;

      expect(await _icmToken.balanceOf(_sentryContract.getAddress())).to.equal(
        0n
      );

      console.log(
        "AFter--",
        { licenseCost },
        await _icmToken.balanceOf(owner),
        await _icmToken.balanceOf(_sentryContract.getAddress())
      );
      const otherAccountBalanceAfter = await ethers.provider.getBalance(
        otherAccount.getAddress()
      );
      // expect(otherAccountBalanceAfter).to.equal(
      //   licenseCost + otherAccountBalanceBefore
      // );
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
