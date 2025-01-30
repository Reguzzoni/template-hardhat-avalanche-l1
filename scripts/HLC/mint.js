// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");
const fs = require("fs");

async function main() {
    const customSecurityAssetAddress = scInfo.customSecurityAssetAddress;
    const adddressToMint = "0x8193E1f855593aC6305D21b744ec708aaF26d202"; // isp lux
    const [admin] = await ethers.getSigners();

    console.log("Registrar address:", admin.address);
    console.log("Security asset address:", customSecurityAssetAddress);
    console.log("Minting to address: " + adddressToMint);

    // Get the Security asset Contract
    const customSecurityAssetContract = await hre.ethers.getContractAt(
        "CustomSecurityAsset",
        customSecurityAssetAddress
    );

    const amountToMint = await customSecurityAssetContract.cap();

    await customSecurityAssetContract.mint(adddressToMint, amountToMint);
    console.log("Mint to " + adddressToMint + " successfully");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
