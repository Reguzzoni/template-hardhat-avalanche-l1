// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");
const fs = require("fs");

async function main() {
    const accounts = await ethers.getSigners();
    const registrar = accounts[0];
    const issuer = accounts[1];
    const buyer = accounts[2];

    const restrictionsAddress = scInfo.restrictionsAddress;

    const sellerAddress = issuer.address;
    const buyerAddress = buyer.address;
    const price = "1000000";
    const tokenAmount = 1;
    const cashLegTokenAmount = 1000000;
    const tipsId = ethers.hexlify(ethers.toUtf8Bytes("2GkKHqy2kk8W6lPlU7dtNJRLXjXWYMKT0V"));
    const hashExecutionKey = ethers.sha256(ethers.toUtf8Bytes("Exec key"));
    const hashCancellationKey = ethers.sha256(ethers.toUtf8Bytes("Canc key"));
    const commercialPaperAddress = scInfo.commercialPaperAddress;
    const customERC20Address = scInfo.customERC20Address;
    const epochTimePlus10Hours = Date.now() + 10 * 60 * 60 * 1000;
    const epochTimeInSeconds = Math.floor(epochTimePlus10Hours / 1000);

    console.log(`Deploying HLC with the account:, ${registrar.address}
        and sellerAddress: ${sellerAddress}
        and buyerAddress: ${buyerAddress}
        and price: ${price}
        and tokenAmount: ${tokenAmount}
        and cashLegTokenAmount: ${cashLegTokenAmount}
        and tipsId: ${tipsId}
        and commercialPaperAddress: ${commercialPaperAddress}
        and customERC20Address: ${customERC20Address}
        and epochTimeInSeconds: ${epochTimeInSeconds}`);

    // Deploy HLC
    const hlcContract = await hre.ethers.deployContract(
        "HLC",
        [
            sellerAddress,
            buyerAddress,
            price,
            tokenAmount,
            cashLegTokenAmount,
            tipsId,
            commercialPaperAddress,
            customERC20Address,
            epochTimeInSeconds,
        ],
        { from: registrar }
    );
    await hlcContract.waitForDeployment();
    console.log("HLC contract deployed with address:", hlcContract.target);
    scInfo.hlcAddress = hlcContract.target;
    // Whitelistin hlc contract in restrictions
    const restrictionsContract = await hre.ethers.getContractAt("Restrictions", restrictionsAddress);
    await restrictionsContract.addWhitelistAddress([hlcContract.target], { from: registrar });
    scInfo.whitelistedAddresses.push(hlcContract.target);

    console.log("HLC contract whitelisted successfully");

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
