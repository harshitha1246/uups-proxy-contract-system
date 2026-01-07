const { upgrades, ethers } = require("hardhat");

async function main() {
  const PROXY_ADDRESS = process.env.PROXY_ADDRESS || "0x..."; // Set during deployment
  console.log("Upgrading TokenVault to V2 at proxy:", PROXY_ADDRESS);

  const TokenVaultV2 = await ethers.getContractFactory("TokenVaultV2");
  const upgraded = await upgrades.upgradeProxy(PROXY_ADDRESS, TokenVaultV2, { kind: "uups" });
  console.log("TokenVault upgraded to V2");
  console.log("Implementation version:", await upgraded.getImplementationVersion());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
