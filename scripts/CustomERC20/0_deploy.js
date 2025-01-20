// scripts/CustomERC20/0_deploy.js
const { ethers } = require("hardhat");

async function main() {
    const accounts = await ethers.getSigners();
    const deployer = accounts[0];

    console.log("Deployer address:", deployer.address);

    // Deploy Restrictions
    const customERC20 = await hre.ethers.deployContract("CustomERC20", { from: deployer });
    await customERC20.waitForDeployment();
    console.log("CustomERC20 deployed with address:", customERC20.target);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
