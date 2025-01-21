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
    const commercialPaperAddress = scInfo.commercialPaperAddress;

    // Coop Exec token to HLC
    const customERC20Contract = await hre.ethers.getContractAt("CustomERC20", customERC20Address);
    const commercialPaperContract = await hre.ethers.getContractAt("CommercialPaper", commercialPaperAddress);
    const hlcContract = await hre.ethers.getContractAt("HLC", hlcAddress);

    console.log("BEFORE DVP - Balance issuer Custom token", await customERC20Contract.balanceOf(issuer.address));
    console.log("BEFORE DVP - Balance buyer commercial paper", await commercialPaperContract.balanceOf(buyer.address));

    // execute dvp
    await hlcContract.connect(registrar).executeDvP();

    console.log("DVP executed successfully");
    console.log("AFTER DVP - Balance issuer Custom token", await customERC20Contract.balanceOf(issuer.address));
    console.log("AFTER DVP - Balance buyer commercial paper", await commercialPaperContract.balanceOf(buyer.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
