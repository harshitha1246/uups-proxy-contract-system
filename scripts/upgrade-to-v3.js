const { ethers, upgrades } = require("hardhat");

async function main() {
  const PROXY_ADDRESS = process.env.PROXY_ADDRESS;
  if (!PROXY_ADDRESS) {
    throw new Error("Set PROXY_ADDRESS in your .env first!");
  }
  console.log("Upgrading TokenVault to V3 at proxy:", PROXY_ADDRESS);

  const TokenVaultV3 = await ethers.getContractFactory("TokenVaultV3");
  const upgraded = await upgrades.upgradeProxy(PROXY_ADDRESS, TokenVaultV3, { kind: "uups" });
  console.log("TokenVault upgraded to V3 at proxy:", upgraded.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
