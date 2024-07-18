import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Subnet", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployContract() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const IcmToken = await ethers.getContractFactory("IcmToken");
    const _icmToken = await IcmToken.deploy();

    const Subnet = await ethers.getContractFactory("Subnet");
    const _subnet = await Subnet.deploy();

    await _subnet.initialize(_icmToken.getAddress(), owner);

    return { _icmToken, _subnet, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should have withdrawalEnabled as FALSE", async function () {
      const { _subnet } = await loadFixture(deployContract);

      expect(await _subnet.withdrawalEnabled()).to.equal(false);
    });
  });

  describe("Staking...", function () {
    const subnet = "193430c8-7927-2d6d-c293-27d03420ca0c";
    const subnetHex = `0x${subnet.replaceAll("-", "")}`;
    const subnetAmountVal = 2000;
    const subnetAmountVal2: bigint = BigInt(6000 * 10 ** 18);
    it(`Should Subnet ${subnetHex} -- ${subnetAmountVal}`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);

      await _icmToken.approve(_subnet.getAddress(), subnetAmountVal);
      await expect(_subnet.stake(subnetHex, 0)).to.be.revertedWith(
        "You need to stake the minimum amount of tokens"
      );
      await expect(
        _subnet.stake(subnetHex, subnetAmountVal)
      ).to.be.revertedWith("You need to stake more than the minimum stake");
      await _icmToken.approve(_subnet.getAddress(), subnetAmountVal2);
      await expect(_subnet.stake(subnetHex, subnetAmountVal2)).not.to.be
        .reverted;

      expect(await _subnet.subnetBalance(subnetHex)).to.equal(subnetAmountVal2);
    });
  });

  describe("Get Balance...", function () {
    const subnet = "193430c8-7927-2d6d-c293-27d03420ca0c";
    const subnetHex = `0x${subnet.replaceAll("-", "")}`;
    const subnetAmountVal: bigint = BigInt(6000 * 10 ** 18);
    // const minStakable = 5000 * 10**18;
    const minStakable: bigint = BigInt(5000 * 10 ** 18);
    it(`Should Get Balance for Subnet ${subnetHex} -- ${subnetAmountVal} == ${minStakable}`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);

      await _icmToken.approve(_subnet.getAddress(), subnetAmountVal);
      expect(await _subnet.minStakable()).to.equal(minStakable);
      await _subnet.stake(subnetHex, subnetAmountVal);
      expect(await _subnet.getSubnetBalance(subnetHex)).to.equal(
        subnetAmountVal
      );

      expect(
        await _subnet.getSubnetAccountBalance(subnetHex, owner.getAddress())
      ).to.equal(subnetAmountVal);
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
