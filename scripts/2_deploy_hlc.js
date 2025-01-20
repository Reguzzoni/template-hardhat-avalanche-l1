// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");

async function main() {
    const accounts = await ethers.getSigners();
    const registrar = accounts[0];
    const issuer = accounts[1];
    const buyer = accounts[2];

    const restrictionsAddress = "0x6dCde36157aad8C5717d5FCaF5B9C3395BF4841c";

    const sellerAddress = issuer.address;
    const buyerAddress = buyer.address;
    const price = "1000000";
    const tokenAmount = 1;
    const tipsId = ethers.hexlify(ethers.toUtf8Bytes("2GkKHqy2kk8W6lPlU7dtNJRLXjXWYMKT0V"));
    const hashExecutionKey = ethers.sha256(ethers.toUtf8Bytes("Exec key"));
    const hashCancellationKey = ethers.sha256(ethers.toUtf8Bytes("Canc key"));
    const commercialPaperAddress = "0x200CAd4cb158ae8911bA31418e57F49F505D4eE9";

    console.log("Deploying HLC with the account:", registrar.address);

    // Deploy HLC
    const hlcContract = await hre.ethers.deployContract(
        "HLC",
        [
            sellerAddress,
            buyerAddress,
            price,
            tokenAmount,
            tipsId,
            hashExecutionKey,
            hashCancellationKey,
            commercialPaperAddress,
        ],
        { from: registrar }
    );
    await hlcContract.waitForDeployment();
    console.log("HLC contract deployed with address:", hlcContract.target);

    // Whitelistin hlc contract in restrictions
    const restrictionsContract = await hre.ethers.getContractAt("Restrictions", restrictionsAddress);
    await restrictionsContract.addWhitelistAddress([hlcContract.target], { from: registrar });
    console.log("HLC contract whitelisted successfully");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
