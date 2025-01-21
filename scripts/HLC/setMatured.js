// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");

async function main() {
    const commercialPaperAddress = scInfo.commercialPaperAddress;
    const [registrar] = await ethers.getSigners();
    console.log("Registrar address:", registrar.address);

    const commercialPaperContract = await hre.ethers.getContractAt("CommercialPaper", commercialPaperAddress);

    if ((await commercialPaperContract.status()) == 1) {
        console.log("Status is Live");

        await commercialPaperContract.setMatured();
        console.log("Status set to matured successfully");
    } else {
        console.log("Status is not Live, Commercial Paper cannot be matured");
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
