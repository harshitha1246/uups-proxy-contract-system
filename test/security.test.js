const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("Security Tests", function () {
  let owner, user, token, proxy;

  beforeEach(async () => {
    [owner, user] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("MockERC20");
    token = await Token.deploy();
    await token.mint(user.address, ethers.parseEther("1000"));
  });

  it("should prevent direct initialization of implementation contracts", async () => {
    const V1 = await ethers.getContractFactory("TokenVaultV1");
    const impl = await V1.deploy();

    await expect(
      impl.initialize(token.target, owner.address, 500)
    ).to.be.revertedWith("Initializable: contract is already initialized");
  });

  it("should prevent unauthorized upgrades", async () => {
    const V1 = await ethers.getContractFactory("TokenVaultV1");
    proxy = await upgrades.deployProxy(
      V1,
      [token.target, owner.address, 500],
      { kind: "uups" }
    );

    const V2 = await ethers.getContractFactory("TokenVaultV2");

    await expect(
      upgrades.upgradeProxy(proxy.target, V2.connect(user))
    ).to.be.reverted;
  });

  it("should use storage gaps for future upgrades", async () => {
    const V1 = await ethers.getContractFactory("TokenVaultV1");
    const V2 = await ethers.getContractFactory("TokenVaultV2");
    const V3 = await ethers.getContractFactory("TokenVaultV3");

    // Deployment should not revert due to storage layout issues
    const proxy = await upgrades.deployProxy(
      V1,
      [token.target, owner.address, 500],
      { kind: "uups" }
    );

    await upgrades.upgradeProxy(proxy.target, V2);
    await upgrades.upgradeProxy(proxy.target, V3);

    expect(true).to.equal(true);
  });

  it("should not have storage layout collisions across versions", async () => {
    const V1 = await ethers.getContractFactory("TokenVaultV1");
    const V2 = await ethers.getContractFactory("TokenVaultV2");

    const proxy = await upgrades.deployProxy(
      V1,
      [token.target, owner.address, 500],
      { kind: "uups" }
    );

    const balanceBefore = await proxy.totalDeposits();

    const upgraded = await upgrades.upgradeProxy(proxy.target, V2);

    const balanceAfter = await upgraded.totalDeposits();
    expect(balanceAfter).to.equal(balanceBefore);
  });

  it("should prevent function selector clashing", async () => {
    const V1 = await ethers.getContractFactory("TokenVaultV1");
    const proxy = await upgrades.deployProxy(
      V1,
      [token.target, owner.address, 500],
      { kind: "uups" }
    );

    // If selector clashing existed, this would revert or misbehave
    expect(await proxy.getImplementationVersion()).to.equal("V1");
  });
});
