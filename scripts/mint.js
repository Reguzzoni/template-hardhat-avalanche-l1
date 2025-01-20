// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");

async function main() {
    const commercialPaperAddress = "0x01dd8322ce39dbc99d5f5c504dded6b63cf3833b";
    const adddressToMint = "0x0a3e02d3dd35e59318a779d60e68ce803918a757"; // isp lux
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
