// scripts/CustomERC20/1_transfer_token.js
const { ethers } = require("hardhat");
let scInfo = require("../../scInfo.json");

async function main() {
    const accounts = await ethers.getSigners();
    const sender = accounts[0];
    const receivers = [accounts[1], accounts[2]];
    const customERC20Address = scInfo.customERC20Address;

    // Coop Exec token to HLC
    const customERC20Contract = await hre.ethers.getContractAt("CustomERC20", customERC20Address);

    for (let i = 0; i < receivers.length; i++) {
        console.log("Balance sender", await customERC20Contract.balanceOf(sender.address));
        console.log("Balance receiver", await customERC20Contract.balanceOf(receivers[i].address));

        // transfer token to receiver
        await customERC20Contract.transfer(receivers[i].address, 1000000);

        console.log("Balance sender", await customERC20Contract.balanceOf(sender.address));
        console.log("Balance receiver", await customERC20Contract.balanceOf(receivers[i].address));
    }
    console.log("Token transferred to receiver successfully");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
