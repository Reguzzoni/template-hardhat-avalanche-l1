// scripts/CustomERC20/1_transfer_token.js
const { ethers } = require("hardhat");

async function main() {
    const accounts = await ethers.getSigners();
    const sender = accounts[0];
    const receiver = accounts[1];
    const customERC20Address = "0x811B8d66F278004D237d45Bee7F0ee021443b6C9";

    // Coop Exec token to HLC
    const customERC20Contract = await hre.ethers.getContractAt("CustomERC20", customERC20Address);

    console.log("Balance sender", await customERC20Contract.balanceOf(sender.address));
    console.log("Balance receiver", await customERC20Contract.balanceOf(receiver.address));

    // transfer token to receiver
    await customERC20Contract.transfer(receiver.address, 1000);

    console.log("Balance sender", await customERC20Contract.balanceOf(sender.address));
    console.log("Balance receiver", await customERC20Contract.balanceOf(receiver.address));

    console.log("Token transferred to receiver successfully");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
