// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");
const fs = require("fs");

async function main() {
    const commercialPaperAddress = scInfo.commercialPaperAddress;
    const [registrar] = await ethers.getSigners();
    console.log("Registrar address:", registrar.address);

    const commercialPaperContract = await hre.ethers.getContractAt("CommercialPaper", commercialPaperAddress);

    await commercialPaperContract.setLive();
    console.log("Status set to live successfully");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
