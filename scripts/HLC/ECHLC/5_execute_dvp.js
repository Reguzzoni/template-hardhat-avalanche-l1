// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../../scInfo.json");

async function main() {
    const accounts = await ethers.getSigners();
    const admin = accounts[0];
    const issuer = accounts[1];
    const buyer = accounts[2];

    const customERC20Address = scInfo.customERC20Address;
    const hlcAddress = scInfo.hlcAddress;
    const customSecurityAssetAddress = scInfo.customSecurityAssetAddress;

    // Coop Exec token to HLC
    const customERC20Contract = await hre.ethers.getContractAt("CustomERC20", customERC20Address);
    const customSecurityAssetContract = await hre.ethers.getContractAt(
        "CustomSecurityAsset",
        customSecurityAssetAddress
    );
    const hlcContract = await hre.ethers.getContractAt("ECHLC", hlcAddress);

    console.log("BEFORE DVP - Balance issuer Custom token", await customERC20Contract.balanceOf(issuer.address));
    console.log(
        "BEFORE DVP - Balance buyer security asset",
        await customSecurityAssetContract.balanceOf(buyer.address)
    );

    // execute dvp
    await hlcContract.connect(admin).executeDvP();

    console.log("DVP executed successfully");
    console.log("AFTER DVP - Balance issuer Custom token", await customERC20Contract.balanceOf(issuer.address));
    console.log("AFTER DVP - Balance buyer security asset", await customSecurityAssetContract.balanceOf(buyer.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
