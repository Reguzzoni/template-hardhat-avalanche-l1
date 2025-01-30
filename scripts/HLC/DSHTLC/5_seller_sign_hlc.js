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
    const hlcContract = await hre.ethers.getContractAt("DSHTLC", hlcAddress);

    console.log("Start request balance of the  issuer:", issuer.address);
    console.log("Balance issuer", await customSecurityAssetContract.balanceOf(issuer));

    // check assetLegStatus on HLC contract
    let assetLegStatus = await hlcContract.assetLegStatus();
    console.log("assetLegStatus", assetLegStatus);
    if (assetLegStatus != 1) {
        console.log("Asset leg is not deposited");
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

    // check VALIDATION_TIME on HLC contract
    let validationTime = await hlcContract.VALIDATION_TIME();
    console.log("validationTime", validationTime);

    let now = Math.floor(Date.now() / 1000);
    console.log("Current time", now);

    if (validationTime > now) {
        console.log("Validation time is greater than current time, cannot transfer token to HLC");
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

    // check already signed
    let isSellerSigned = await hlcContract.sellerSign();
    console.log("isSellerSigned", isSellerSigned);
    if (isSellerSigned) {
        console.log("Issuer already signed, cannot sign again");
        return;
    }

    const currentTimestamp = await ethers.provider.getBlock("latest").then((block) => block.timestamp);
    console.log("Current block timestamp:", currentTimestamp);

    let isBuyerSigned = await hlcContract.buyerSign();
    console.log("isBuyerSigned", isBuyerSigned);

    console.log("HLC try sign by Issuer");
    await hlcContract.connect(issuer).sign();
    console.log("HLC Signed");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
