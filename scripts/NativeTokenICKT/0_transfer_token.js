// scripts/NativeTokenICKT/0_transfer_token.js
const { ethers } = require("hardhat");

async function main() {
    const accounts = await ethers.getSigners();
    const sender = accounts[0];
    const receiver = accounts[1];

    // transfer native token to receiver
    const amount = ethers.parseEther("0.001"); // 1.0 ETH

    // transfer the amount
    const tx = await sender.sendTransaction({
        to: receiver.address,
        value: amount,
    });

    console.log(`Sent trx: ${tx.hash}`);

    // wait for the transaction to be mined
    await tx.wait();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
