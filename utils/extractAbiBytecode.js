const fs = require("fs");

let contractsList = ["CommercialPaper", "CustomERC20", "HLC", "Restrictions"];

for (let i = 0; i < contractsList.length; i++) {
    // ALLERT! YOU MUST UPDATE FILENAME WITH YOUR PROJECT PATH
    const fileName = `D:/IntesaSanpaolo/Projects/Avalanche/avalanche-sc-hardhat/contractsInfo/${contractsList[i]}/${contractsList[i]}`;

    // Read the JSON file
    const jsonData = fs.readFileSync(
        `D:/IntesaSanpaolo/Projects/Avalanche/avalanche-sc-hardhat/artifacts/contracts/${contractsList[i]}.sol/${contractsList[i]}.json`,
        "utf-8"
    );

    // Parse the JSON data
    const json = JSON.parse(jsonData);

    // Extract the "abi" and "bytecode" fields
    let abi = JSON.stringify(json.abi);
    let bytecode = json.bytecode;

    if (bytecode.startsWith("0x")) {
        bytecode = bytecode.substring(2);
    }

    // Convert the bytecode array to a string
    bytecode = bytecode.toString();

    console.log("abi: " + abi);
    console.log("bytecode: " + bytecode);

    // Write the "abi" and "bytecode" fields to separate files
    fs.writeFileSync(fileName + ".abi", abi);
    fs.writeFileSync(fileName + ".bin", bytecode);
}
