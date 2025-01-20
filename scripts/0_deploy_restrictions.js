// scripts/deploy_restrictions.js
const { ethers } = require("hardhat");

async function main() {
    const accounts = await ethers.getSigners();
    const registrar = accounts[0];

    console.log("Deploying Restrictions with the account:", registrar.address);

    // Deploy Restrictions
    const restrictionsContract = await hre.ethers.deployContract("Restrictions", { from: registrar });
    await restrictionsContract.waitForDeployment();
    console.log("Restrictions deployed with address:", restrictionsContract.target);

    await restrictionsContract.addWhitelistAddress(
        ["0xFE3B557E8Fb62b89F4916B721be55cEb828dBd73", "0x627306090abaB3A6e1400e9345bC60c78a8BEf57"],
        { from: registrar }
    );
    console.log("Addresses whitelisted successfully");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
