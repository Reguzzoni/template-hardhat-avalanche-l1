// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");
const fs = require("fs");

async function main() {
    const commercialPaperAddress = scInfo.commercialPaperAddress;
    const adddressToMint = "0x8193E1f855593aC6305D21b744ec708aaF26d202"; // isp lux
    const [registrar] = await ethers.getSigners();

    console.log("Registrar address:", registrar.address);
    console.log("Commercial Paper address:", commercialPaperAddress);
    console.log("Minting to address: " + adddressToMint);

    // Get the Commercial Paper Contract
    const commercialPaperContract = await hre.ethers.getContractAt("CommercialPaper", commercialPaperAddress);

    const amountToMint = await commercialPaperContract.cap();

    await commercialPaperContract.mint(adddressToMint, amountToMint);
    console.log("Mint to " + adddressToMint + " successfully");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
