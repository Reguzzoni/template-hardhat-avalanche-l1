// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");
const fs = require("fs");

const restrictionsAddress = scInfo.restrictionsAddress;

async function main() {
    const accounts = await ethers.getSigners();
    const registrar = accounts[0];
    const issuer = accounts[1];
    const buyer = accounts[2];

    const isLive = true;
    const name = "ISP ECP";
    const symbol = "iECP";
    const isin = "XS0000000001";
    const issuanceCountry = "XS";
    const currency = "EXP";
    const maturity = "01/04/2024";
    const minimumDenomination = 1;
    const addInfoUri = "https://www.documentation.com";
    const checksum = "checksum";
    const cap = 1;
    const issuerAddress = issuer.address;

    console.log(
        "Deploying CommercialPaper with the account:",
        registrar.address,
        " and restriction address:",
        restrictionsAddress
    );

    // Deploy Restrictions
    const commercialPaperContract = await hre.ethers.deployContract(
        "CommercialPaper",
        [
            isLive,
            name,
            symbol,
            isin,
            issuanceCountry,
            currency,
            maturity,
            minimumDenomination,
            addInfoUri,
            checksum,
            cap,
            restrictionsAddress,
            issuerAddress,
        ],
        { from: registrar }
    );
    await commercialPaperContract.waitForDeployment();
    console.log("CommercialPaper contract deployed with address:", commercialPaperContract.target);

    scInfo.commercialPaperAddress = commercialPaperContract.target;

    await commercialPaperContract.mint(issuer.address, cap, { from: registrar });
    console.log("Minted " + cap + " " + symbol + " to issuer successfully");

    await fs.writeFileSync("scInfo.json", JSON.stringify(scInfo), "utf-8", (err) => {
        if (err) console.log("Error writing file cause:", err);
    });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
