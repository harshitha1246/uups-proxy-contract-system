const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("Upgrade V2 to V3", () => {
  let proxyAddress, token, owner, user1;

  before(async () => {
    [owner, user1] = await ethers.getSigners();
    const TokenFactory = await ethers.getContractFactory("MockERC20");
    token = await TokenFactory.deploy();
    await token.waitForDeployment();
    
    const V2Factory = await ethers.getContractFactory("TokenVaultV2");
    const proxy = await upgrades.deployProxy(V2Factory, [token.target, owner.address, 500], { kind: "uups" });
    await proxy.waitForDeployment();
    proxyAddress = proxy.target;
    
    await token.mint(user1.address, ethers.parseEther("10000"));
    await token.connect(user1).approve(proxyAddress, ethers.MaxUint256);
  });

  it("should preserve all V2 state after upgrade", async () => {
    const vaultV2 = await ethers.getContractAt("TokenVaultV2", proxyAddress);
    await vaultV2.connect(user1).deposit(ethers.parseEther("1000"));
    const balanceBefore = await vaultV2.balanceOf(user1.address);
    
    const V3Factory = await ethers.getContractFactory("TokenVaultV3");
    await upgrades.upgradeProxy(proxyAddress, V3Factory, { kind: "uups" });
    
    const vaultV3 = await ethers.getContractAt("TokenVaultV3", proxyAddress);
    const balanceAfter = await vaultV3.balanceOf(user1.address);
    expect(balanceAfter).to.equal(balanceBefore);
  });

  it("should allow setting withdrawal delay", async () => {
    const vaultV3 = await ethers.getContractAt("TokenVaultV3", proxyAddress);
    await vaultV3.setWithdrawalDelay(86400);
    expect(await vaultV3.getWithdrawalDelay()).to.equal(86400);
  });

  it("should handle withdrawal requests correctly", async () => {
    const vaultV3 = await ethers.getContractAt("TokenVaultV3", proxyAddress);
    const balance = await vaultV3.balanceOf(user1.address);
    await vaultV3.connect(user1).requestWithdrawal(balance);
    const request = await vaultV3.getWithdrawalRequest(user1.address);
    expect(request.amount).to.equal(balance);
  });

  it("should enforce withdrawal delay", async () => {
    const vaultV3 = await ethers.getContractAt("TokenVaultV3", proxyAddress);
    await expect(vaultV3.connect(user1).executeWithdrawal()).to.be.revertedWith("Withdrawal delay not met");
  });

  it("should allow emergency withdrawals", async () => {
    const vaultV3 = await ethers.getContractAt("TokenVaultV3", proxyAddress);
    const tokenBefore = await token.balanceOf(user1.address);
    await vaultV3.connect(user1).emergencyWithdraw();
    const tokenAfter = await token.balanceOf(user1.address);
    expect(tokenAfter).to.be.gt(tokenBefore);
  });

  it("should prevent premature withdrawal execution", async () => {
    await token.mint(user1.address, ethers.parseEther("500"));
    const vaultV3 = await ethers.getContractAt("TokenVaultV3", proxyAddress);
    await vaultV3.connect(user1).deposit(ethers.parseEther("500"));
    await vaultV3.setWithdrawalDelay(86400);
    const balance = await vaultV3.balanceOf(user1.address);
    await vaultV3.connect(user1).requestWithdrawal(balance);
    await expect(vaultV3.connect(user1).executeWithdrawal()).to.be.revertedWith("Withdrawal delay not met");
  });
});
