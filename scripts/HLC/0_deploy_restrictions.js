// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");
const fs = require("fs");

async function main() {
    const accounts = await ethers.getSigners();
    const registrar = accounts[0];
    const issuer = accounts[1];
    const holder = accounts[2];

    console.log("Deploying Restrictions with the account:", registrar.address);

    // Deploy Restrictions
    const restrictionsContract = await hre.ethers.deployContract("Restrictions", { from: registrar });
    await restrictionsContract.waitForDeployment();
    console.log("Restrictions deployed with address:", restrictionsContract.target);

    scInfo.restrictionsAddress = restrictionsContract.target;

    await restrictionsContract.addWhitelistAddress([issuer.address, holder.address], { from: registrar });
    console.log("Addresses whitelisted successfully");

    scInfo.whitelistedAddresses = [issuer.address, holder.address];

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
