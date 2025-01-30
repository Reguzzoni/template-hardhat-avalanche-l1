// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");
const fs = require("fs");

async function main() {
    const customSecurityAssetAddress = scInfo.customSecurityAssetAddress;
    const [admin] = await ethers.getSigners();
    console.log("Registrar address:", admin.address);

    const customSecurityAssetContract = await hre.ethers.getContractAt(
        "CustomSecurityAsset",
        customSecurityAssetAddress
    );

    await customSecurityAssetContract.setLive();
    console.log("Status set to live successfully");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
