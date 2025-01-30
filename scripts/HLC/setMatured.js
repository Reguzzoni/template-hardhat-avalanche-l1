// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");

async function main() {
    const customSecurityAssetAddress = scInfo.customSecurityAssetAddress;
    const [admin] = await ethers.getSigners();
    console.log("Registrar address:", admin.address);

    const customSecurityAssetContract = await hre.ethers.getContractAt(
        "CustomSecurityAsset",
        customSecurityAssetAddress
    );

    if ((await customSecurityAssetContract.status()) == 1) {
        console.log("Status is Live");

        await customSecurityAssetContract.setMatured();
        console.log("Status set to matured successfully");
    } else {
        console.log("Status is not Live, Security asset cannot be matured");
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
