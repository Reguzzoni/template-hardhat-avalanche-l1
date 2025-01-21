// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");

async function main() {
    const accounts = await ethers.getSigners();
    const registrar = accounts[0];
    const issuer = accounts[1];
    const buyer = accounts[2];

    const customERC20Address = scInfo.customERC20Address;
    const hlcAddress = scInfo.hlcAddress;

    // Coop Exec token to HLC
    const customERC20Contract = await hre.ethers.getContractAt("CustomERC20", customERC20Address);
    const hlcContract = await hre.ethers.getContractAt("HLC", hlcAddress);

    console.log("Balance buyer", await customERC20Contract.balanceOf(buyer.address));

    // check if the issuer has enough token
    const tokenAmount = 1000000;
    if ((await customERC20Contract.balanceOf(buyer)) < tokenAmount) {
        console.log("Insufficient token balance");
        return;
    }

    // check assetLegStatus on HLC contract
    let paymentLegStatus = await hlcContract.paymentLegStatus();
    console.log("paymentLegStatus", paymentLegStatus);
    if (paymentLegStatus != 0) {
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

    // check asset_amount
    let paymentTokenAmount = await hlcContract.PAYMENT_TOKEN_AMOUNT();
    console.log("paymentTokenAmount", paymentTokenAmount);
    if (paymentTokenAmount != tokenAmount) {
        console.log("Payment amount is not equal to token amount, cannot transfer token to HLC");
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

    await customERC20Contract.connect(buyer).approve(hlcAddress, tokenAmount);
    console.log("Token approved to HLC successfully");

    await hlcContract.connect(buyer).depositPaymentToken();
    console.log("Token transferred to HLC successfully");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
