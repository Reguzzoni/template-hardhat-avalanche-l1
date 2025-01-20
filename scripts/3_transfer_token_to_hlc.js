// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");

async function main() {
    const accounts = await ethers.getSigners();
    const registrar = accounts[0];
    const issuer = accounts[1];
    const buyer = accounts[2];

    const commercialPaperAddress = "0x200CAd4cb158ae8911bA31418e57F49F505D4eE9";
    const hlcAddress = "0x186461A536c4a8659AbC86c845D5da38A706626b";

    // Coop Exec token to HLC
    const commercialPaperContract = await hre.ethers.getContractAt("CommercialPaper", commercialPaperAddress);

    console.log("Balance issuer", await commercialPaperContract.balanceOf(issuer.address));
    //await commercialPaperContract.transfer(hlcAddress, tokenAmount, { from: issuer });
    console.log("Token transferred to HLC successfully");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
