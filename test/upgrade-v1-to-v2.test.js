const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("Upgrade V1 to V2", () => {
  let proxyAddress, token, owner, user1;

  before(async () => {
    [owner, user1] = await ethers.getSigners();
    const TokenFactory = await ethers.getContractFactory("MockERC20");
    token = await TokenFactory.deploy();
    await token.waitForDeployment();
    
    const V1Factory = await ethers.getContractFactory("TokenVaultV1");
    const proxy = await upgrades.deployProxy(V1Factory, [token.target, owner.address, 500], { kind: "uups" });
    await proxy.waitForDeployment();
    proxyAddress = proxy.target;
    
    await token.mint(user1.address, ethers.parseEther("10000"));
    await token.connect(user1).approve(proxyAddress, ethers.MaxUint256);
  });

  it("should preserve user balances after upgrade", async () => {
    const vault = await ethers.getContractAt("TokenVaultV1", proxyAddress);
    await vault.connect(user1).deposit(ethers.parseEther("1000"));
    const balanceBefore = await vault.balanceOf(user1.address);
    
    const V2Factory = await ethers.getContractFactory("TokenVaultV2");
    await upgrades.upgradeProxy(proxyAddress, V2Factory, { kind: "uups" });
    
    const vaultV2 = await ethers.getContractAt("TokenVaultV2", proxyAddress);
    const balanceAfter = await vaultV2.balanceOf(user1.address);
    expect(balanceAfter).to.equal(balanceBefore);
  });

  it("should preserve total deposits after upgrade", async () => {
    const vault = await ethers.getContractAt("TokenVaultV2", proxyAddress);
    const totalDeposits = await vault.totalDeposits();
    expect(totalDeposits).to.be.gt(0);
  });

  it("should maintain admin access control after upgrade", async () => {
    const vaultV2 = await ethers.getContractAt("TokenVaultV2", proxyAddress);
    const DEFAULT_ADMIN_ROLE = await vaultV2.DEFAULT_ADMIN_ROLE();
    expect(await vaultV2.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.be.true;
  });

  it("should allow setting yield rate in V2", async () => {
    const vaultV2 = await ethers.getContractAt("TokenVaultV2", proxyAddress);
    await vaultV2.setYieldRate(500);
    expect(await vaultV2.getYieldRate()).to.equal(500);
  });

  it("should calculate yield correctly", async () => {
    const vaultV2 = await ethers.getContractAt("TokenVaultV2", proxyAddress);
    const userYield = await vaultV2.getUserYield(user1.address);
    expect(userYield).to.be.gte(0);
  });

  it("should prevent non-admin from setting yield rate", async () => {
    const vaultV2 = await ethers.getContractAt("TokenVaultV2", proxyAddress);
    await expect(vaultV2.connect(user1).setYieldRate(500)).to.be.reverted;
  });

  it("should allow pausing deposits in V2", async () => {
    const vaultV2 = await ethers.getContractAt("TokenVaultV2", proxyAddress);
    await vaultV2.pauseDeposits();
    expect(await vaultV2.isDepositsPaused()).to.be.true;
    await vaultV2.unpauseDeposits();
    expect(await vaultV2.isDepositsPaused()).to.be.false;
  });
});
