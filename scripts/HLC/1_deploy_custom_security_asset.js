// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");
const fs = require("fs");

const restrictionsAddress = scInfo.restrictionsAddress;

async function main() {
    const accounts = await ethers.getSigners();
    const admin = accounts[0];
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
        "Deploying CustomSecurityAsset with the account:",
        admin.address,
        " and restriction address:",
        restrictionsAddress
    );

    // Deploy Restrictions
    const customSecurityAssetContract = await hre.ethers.deployContract(
        "CustomSecurityAsset",
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
        { from: admin }
    );
    await customSecurityAssetContract.waitForDeployment();
    console.log("CustomSecurityAsset contract deployed with address:", customSecurityAssetContract.target);

    scInfo.customSecurityAssetAddress = customSecurityAssetContract.target;

    await customSecurityAssetContract.mint(issuer.address, cap, { from: admin });
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
