// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../../scInfo.json");

async function main() {
    const accounts = await ethers.getSigners();
    // const admin = accounts[0];
    const issuer = accounts[1];
    // const buyer = accounts[2];

    const customSecurityAssetAddress = scInfo.customSecurityAssetAddress;
    const hlcAddress = scInfo.hlcAddress;

    // Coop Exec token to HLC
    const customSecurityAssetContract = await hre.ethers.getContractAt(
        "CustomSecurityAsset",
        customSecurityAssetAddress
    );
    const hlcContract = await hre.ethers.getContractAt("ECHLC", hlcAddress);

    console.log("Start request balance of the  issuer:", issuer.address);
    console.log("Balance issuer", await customSecurityAssetContract.balanceOf(issuer));

    // check if the issuer has enough token
    const tokenAmount = 1;
    if ((await customSecurityAssetContract.balanceOf(issuer)) < tokenAmount) {
        console.log("Insufficient token balance");
        return;
    }

    // check assetLegStatus on HLC contract
    let assetLegStatus = await hlcContract.assetLegStatus();
    console.log("assetLegStatus", assetLegStatus);
    if (assetLegStatus != 0) {
        console.log("Asset leg is not deposited, cannot transfer token to HLC");
        return;
    }

    // check hlcStatus is initialized on HLC contract
    let hlcStatus = await hlcContract.hlcStatus();
    console.log("hlcStatus", hlcStatus);
    if (hlcStatus != 0) {
        console.log("HLC status is not initialized, cannot transfer token to HLC");
        return;
    }

    // check EXPIRE_TIME on HLC contract
    let expireTime = await hlcContract.EXPIRE_TIME();
    console.log("expireTime", expireTime);
    if (expireTime < Math.floor(Date.now() / 1000)) {
        console.log("HLC has expired, cannot transfer token to HLC");
        return;
    }

    // check asset_amount
    let assetAmount = await hlcContract.ASSET_TOKEN_AMOUNT();
    console.log("assetAmount", assetAmount);
    if (assetAmount != tokenAmount) {
        console.log("Asset amount is not equal to token amount, cannot transfer token to HLC");
        return;
    }

    let customSecurityAssetIsLive = await customSecurityAssetContract.status();
    console.log("customSecurityAssetIsLive", customSecurityAssetIsLive);
    if (customSecurityAssetIsLive != 1) {
        console.log("Security asset is not Live, cannot transfer token to HLC");
        return;
    }

    let restrictionsAddress = scInfo.restrictionsAddress;
    const restrictionsContract = await hre.ethers.getContractAt("Restrictions", restrictionsAddress);
    let isWhitelisted = await restrictionsContract.isWhitelisted(hlcAddress);
    console.log("isWhitelisted", isWhitelisted);
    if (!isWhitelisted) {
        console.log("HLC is not whitelisted, cannot transfer token to HLC");
        return;
    }

    let issuerAddressFromHlc = await hlcContract.SELLER();
    console.log("issuerAddressFromHlc", issuerAddressFromHlc);
    if (issuerAddressFromHlc != issuer.address) {
        console.log("Issuer address is not the same as the issuer address from HLC, cannot transfer token to HLC");
        return;
    }

    let isWhitelistedIssuer = await restrictionsContract.isWhitelisted(issuer);
    console.log("isWhitelistedIssuer", isWhitelistedIssuer);
    if (!isWhitelistedIssuer) {
        console.log("Issuer is not whitelisted, cannot transfer token to HLC");
        return;
    }

    //await customSecurityAssetContract.transfer(hlcAddress, tokenAmount, { from: issuer });
    await customSecurityAssetContract.connect(issuer).approve(hlcAddress, 1);
    console.log("Token approved to HLC successfully");
    await hlcContract.connect(issuer).depositAssetToken();
    console.log("Token transferred to HLC successfully");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
