## Sample Hardhat Project connected to isp climate kick layer 1 local avalanche network

This project demonstrates a basic use case of Hardhat. It includes a sample contract and a script to deploy that contract.

After setting the .env variables, you can try running the following tasks:

```shell
npx hardhat run .\scripts\CustomERC20\0_deploy.js --network private_avalanche_isp_climatekick_l1_test

npx hardhat run .\scripts\CustomERC20\1_transfer_token.js --network private_avalanche_isp_climatekick_l1_test

npx hardhat run .\scripts\NativeTokenICKT\0_transfer_token.js --network private_avalanche_isp_climatekick_l1_test
```

## Get Native Token

The current native token of the network is ICKT. You can obtain some ICKT by running the following command:

```shell
npx hardhat run .\scripts\NativeTokenICKT\0_transfer_token.js --network private_avalanche_isp_climatekick_l1_test
```

The private_avalanche_isp_climatekick_l1_test network is set by default in the hardhat.config.js file.

## Execute Flow HLC full ledger

It is also possible to execute a flow that creates a full ledger DvP transaction using a custom ERC20 token and a security asset.

```shell
./utils/executeHLCFullLedger_ECHLC.bat
```

This flow is based on the scInfo.json file, which contains the information about the deployed smart contract.

To reset the scInfo.json, you can use the following .bat file:

```shell
./utils/resetScInfo.bat
```

### Steps HLC flow

Clean the scInfo.json file

```shell
node .\scripts\HLC\resetScInfo.js
```

Request native token ICKT in order to pay gas fee

```shell
call npx hardhat run ./scripts/NativeTokenICKT/0_transfer_token.js
```

Deploy the ERC20 custom used to "pay" the security asset

```shell
call npx hardhat run ./scripts/CustomERC20/0_deploy.js
```

Transfer the custom ERC20 token to the buyer and seller

```shell
call npx hardhat run ./scripts/CustomERC20/1_transfer_token.js
```

Deploy the restrictions contract dedicated to whitelist the security asset holders

```shell
call npx hardhat run ./scripts/HLC/0_deploy_restrictions.js
```

Deploy the security asset representing the asset

```shell
call npx hardhat run ./scripts/HLC/1_deploy_custom_security_asset.js
```

Deploy the HLC contract, an escrow account where tokens are locked until the DvP is executed

```shell
call npx hardhat run ./scripts/HLC/ECHLC/2_deploy_hlc.js
```

Transfer the security asset to the HLC contract

```shell
call npx hardhat run ./scripts/HLC/ECHLC/3_seller_transfer_token_to_hlc.js
```

Transfer the custom ERC20 token to the HLC contract

```shell
call npx hardhat run ./scripts/HLC/ECHLC/4_buyer_transfer_token_to_hlc.js
```

Execute the DvP transaction

```shell
call npx hardhat run ./scripts/HLC/ECHLC/5_execute_dvp.js
```

## Slither report

In order to generate a report of slither, execute the .bat file:

```shell
./utils/runSlitherReport.bat
```

It will create a report on the slither folder slitherReport.

## ENV file

```shell
PRIVATE_KEY_1 deployer and admin
```

```shell
PRIVATE_KEY_2 seller and issuer
```

```shell
PRIVATE_KEY_3 buyer and holder
```

```shell
PRIVATE_KEY_4 main airdrop account
```

```shell
RPC_URL_AVALANCHE_L1_TEST RPC URL of the avalanche network
```

```shell
RPC_BEARER_TOKEN_AVALANCHE_L1_TEST Bearer token of the avalanche network
```

## ABI and bin extract

In order to extract the abi and the bin of a contract, you can use the following command:

```shell
node ./utils/extractAbiByteCode.js
```
