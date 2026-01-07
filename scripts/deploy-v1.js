const { upgrades, ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const token = await MockERC20.deploy();
  await token.waitForDeployment();
  console.log("MockERC20 deployed to:", token.target);

  const TokenVaultV1 = await ethers.getContractFactory("TokenVaultV1");
  const proxy = await upgrades.deployProxy(
    TokenVaultV1,
    [token.target, deployer.address, 500],
    { kind: "uups" }
  );
  await proxy.waitForDeployment();
  console.log("TokenVaultV1 proxy deployed to:", proxy.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
