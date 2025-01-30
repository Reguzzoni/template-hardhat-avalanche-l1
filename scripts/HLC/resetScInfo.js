// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");
const fs = require("fs");

async function main() {
    // reset scInfo.json
    scInfo = {
        customERC20Address: "",
        hlcAddress: "",
        customSecurityAssetAddress: "",
        restrictionsAddress: "",
        whitelistedAddresses: [],
    };

    fs.writeFileSync("scInfo.json", JSON.stringify(scInfo, null, 2));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
