// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");

async function main() {
    const commercialPaperAddress = "0x01dd8322ce39dbc99d5f5c504dded6b63cf3833b";
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
