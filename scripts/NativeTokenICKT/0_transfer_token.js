// scripts/NativeTokenICKT/0_transfer_token.js
const { ethers } = require("hardhat");

async function main() {
    const accounts = await ethers.getSigners();
    const sender = accounts[3];
    const receivers = [accounts[0], accounts[1], accounts[2]];

    // transfer native token to receiver
    const amount = ethers.parseEther("1"); // 1.0 ETH

    for (let i = 0; i < receivers.length; i++) {
        // transfer the amount
        const tx = await sender.sendTransaction({
            to: receivers[i].address,
            value: amount,
        });

        console.log(`Sent native token to ${receivers[i].address} trx: ${tx.hash}`);

        // wait for the transaction to be mined
        await tx.wait();
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
