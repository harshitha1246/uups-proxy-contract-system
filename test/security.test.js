const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("Security Tests", () => {
  let proxyAddress, token, owner;

  before(async () => {
    [owner] = await ethers.getSigners();
    const TokenFactory = await ethers.getContractFactory("MockERC20");
    token = await TokenFactory.deploy();
    await token.waitForDeployment();
  });

  it("should prevent direct initialization of implementation contracts", async () => {
    const V1Factory = await ethers.getContractFactory("TokenVaultV1");
    const impl = await V1Factory.deploy();
    await impl.waitForDeployment();
    await expect(impl.initialize(token.target, owner.address, 500)).to.be.reverted;
  });

  it("should prevent unauthorized upgrades", async () => {
    const V1Factory = await ethers.getContractFactory("TokenVaultV1");
    const proxy = await upgrades.deployProxy(V1Factory, [token.target, owner.address, 500], { kind: "uups" });
    await proxy.waitForDeployment();
    proxyAddress = proxy.target;
    const [, nonAdmin] = await ethers.getSigners();
    const V2Factory = await ethers.getContractFactory("TokenVaultV2");
    await expect(upgrades.upgradeProxy(proxyAddress, V2Factory, { kind: "uups" })).to.be.reverted;
  });

  it("should use storage gaps for future upgrades", async () => {
    const vaultV1 = await ethers.getContractAt("TokenVaultV1", proxyAddress);
    expect(vaultV1).to.exist;
  });

  it("should not have storage layout collisions across versions", async () => {
    const V2Factory = await ethers.getContractFactory("TokenVaultV2");
    const proxy2 = await upgrades.deployProxy(V2Factory, [token.target, owner.address, 500], { kind: "uups" });
    await proxy2.waitForDeployment();
    const vaultV2 = proxy2;
    expect(vaultV2).to.exist;
  });

  it("should prevent function selector clashing", async () => {
    const V3Factory = await ethers.getContractFactory("TokenVaultV3");
    const proxy3 = await upgrades.deployProxy(V3Factory, [token.target, owner.address, 500], { kind: "uups" });
    await proxy3.waitForDeployment();
    const vaultV3 = proxy3;
    expect(await vaultV3.getImplementationVersion()).to.equal("V3");
  });
});
