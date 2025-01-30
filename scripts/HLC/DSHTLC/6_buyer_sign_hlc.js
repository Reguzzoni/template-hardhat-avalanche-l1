// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../../scInfo.json");

async function main() {
    const accounts = await ethers.getSigners();
    // const admin = accounts[0];
    const issuer = accounts[1];
    const buyer = accounts[2];

    const customSecurityAssetAddress = scInfo.customSecurityAssetAddress;
    const customERC20Address = scInfo.customERC20Address;
    const hlcAddress = scInfo.hlcAddress;

    // Coop Exec token to HLC

    const customERC20Contract = await hre.ethers.getContractAt("CustomERC20", customERC20Address);
    const customSecurityAssetContract = await hre.ethers.getContractAt(
        "CustomSecurityAsset",
        customSecurityAssetAddress
    );
    const hlcContract = await hre.ethers.getContractAt("DSHTLC", hlcAddress);

    console.log("Balance buyer", await customERC20Contract.balanceOf(buyer.address));

    // check assetLegStatus on HLC contract
    let paymentLegStatus = await hlcContract.paymentLegStatus();
    console.log("paymentLegStatus", paymentLegStatus);
    if (paymentLegStatus != 1) {
        console.log("Payment leg is not deposited, cannot transfer token to HLC");
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
    if (validationTime > expireTime) {
        console.log("Validation time is greater than expire time, cannot transfer token to HLC");
        return;
    }

    let now = Math.floor(Date.now() / 1000);
    console.log("Current time", now);

    if (validationTime > now) {
        console.log("Validation time is greater than current time, cannot transfer token to HLC");
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

    let buyerAddressFromHlc = await hlcContract.BUYER();
    console.log("buyerAddressFromHlc", buyerAddressFromHlc);
    if (buyerAddressFromHlc != buyer.address) {
        console.log("Buyer address is not the same as the buyer address from HLC, cannot transfer token to HLC");
        return;
    }

    let isWhitelistedBuyer = await restrictionsContract.isWhitelisted(buyer);
    console.log("isWhitelistedBuyer", isWhitelistedBuyer);
    if (!isWhitelistedBuyer) {
        console.log("Buyer is not whitelisted, cannot transfer token to HLC");
        return;
    }

    console.log("BEFORE DVP - Balance issuer Custom token", await customERC20Contract.balanceOf(issuer.address));
    console.log(
        "BEFORE DVP - Balance buyer security asset",
        await customSecurityAssetContract.balanceOf(buyer.address)
    );

    console.log("Buyer try to sign");
    await hlcContract.connect(buyer).sign();
    console.log("HLC signed and transferred");

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
