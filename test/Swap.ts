import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { IcmToken, Swap } from "../typechain-types";
import { BaseContract, ContractTransactionResponse } from "ethers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

let owner: HardhatEthersSigner;

let icmToken: IcmToken & {
  deploymentTransaction(): ContractTransactionResponse;
};

let swap: Swap & {
  deploymentTransaction(): ContractTransactionResponse;
};

let xToken: BaseContract & {
  deploymentTransaction(): ContractTransactionResponse;
} & Omit<BaseContract, keyof BaseContract>;

describe("Swap", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_GWEI = 1_000_000_000;

    const lockedAmount = ONE_GWEI;

    // Contracts are deployed using the first signer/account by default
    const [_owner, otherAccount] = await ethers.getSigners();

    const IcmToken = await ethers.getContractFactory("IcmToken");
    const _icmToken = await IcmToken.deploy();

    const xIcmToken = await ethers.getContractFactory("xMLTToken");
    const _xToken = await xIcmToken.deploy();

    const Swap = await ethers.getContractFactory("Swap");
    const _swap = await Swap.deploy();
    await _swap.initialize(_icmToken.getAddress(), _xToken.getAddress());

    return { _swap, _xToken, _icmToken, lockedAmount, _owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should have 3 penalties", async function () {
      const { _swap, _xToken, _icmToken, _owner } = await loadFixture(
        deployOneYearLockFixture
      );
      swap = _swap;
      xToken = _xToken;
      icmToken = _icmToken;
      owner = _owner;

      await expect(swap.penalties(2)).to.not.be.reverted;
      await expect(swap.penalties(3)).to.be.reverted;
    });

    it("Should be able to swapXForTokens", async function () {
      // const { owner } = await loadFixture(deployOneYearLockFixture);
      const amountVal: bigint = BigInt(6000 * 10 ** 18);

      await expect(swap.userSwaps(owner.getAddress(), 0)).to.be.reverted;
      await xToken.approve(swap.getAddress(), amountVal);
      expect((await swap.swapXForTokens(amountVal, 100)).toString()).to.not.be
        .reverted;

      await expect(swap.userSwaps(owner.getAddress(), 0)).to.not.be.reverted;
    });

    it("Should be able to claimToken", async function () {
      // const { owner } = await loadFixture(deployOneYearLockFixture);
      const amountVal: bigint = BigInt(6000 * 10 ** 18);
      let tokenBalanceVal: bigint = BigInt(
        ethers.parseEther("1000000000000000").toString()
      );

      expect(await icmToken.balanceOf(owner.address)).to.equal(tokenBalanceVal);

      await expect(swap.claimToken(0)).to.be.revertedWith(
        "Duration has not been reached"
      );
    });

    it("Should be able to swapXForTokens for a zero day", async function () {
      // const { owner } = await loadFixture(deployOneYearLockFixture);
      const amountVal: bigint = BigInt(6000 * 10 ** 18);
      let tokenBalanceVal: bigint = BigInt(
        ethers.parseEther("1000000000000000").toString()
      );

      expect(await icmToken.balanceOf(owner.address)).to.equal(tokenBalanceVal);

      await xToken.approve(swap.getAddress(), amountVal);
      await icmToken.transfer(swap.getAddress(), amountVal);
      expect(await icmToken.balanceOf(owner.address)).to.equal(
        tokenBalanceVal - amountVal
      );
      expect((await swap.swapXForTokens(amountVal, 0)).toString()).to.not.be
        .reverted;
      let total = tokenBalanceVal - amountVal;
      total = total + (amountVal * 5n) / 100n;
      expect(await icmToken.balanceOf(owner.address)).to.equal(total);
      

      await xToken.approve(swap.getAddress(), amountVal);
      expect((await swap.swapXForTokens(amountVal, 0))).to.not.be
        .reverted;


    });

    it("Should not be able to claimToken more the once", async function () {
      // const { owner } = await loadFixture(deployOneYearLockFixture);
      const amountVal: bigint = BigInt(6000 * 10 ** 18);
      

      await expect(swap.claimToken(1)).to.be.revertedWith(
        "Claim has been collected"
      );
    });
  });
});
