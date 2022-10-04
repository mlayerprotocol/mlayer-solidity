import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("IcmToken", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_GWEI = 1_000_000_000;

    const lockedAmount = ONE_GWEI;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const IcmToken = await ethers.getContractFactory("ERC20");
    const _icmToken = await IcmToken.deploy();

    return { _icmToken, lockedAmount, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should have total Supply of 1000000000", async function () {
      const { _icmToken } = await loadFixture(deployOneYearLockFixture);

      expect(await _icmToken.totalSupply()).to.equal(1000000000);
    });

    it("Should give all token to the right owner", async function () {
      const { _icmToken, owner } = await loadFixture(deployOneYearLockFixture);

      expect(await _icmToken.balanceOf(owner.address)).to.equal(1000000000);
    });
  });
});
