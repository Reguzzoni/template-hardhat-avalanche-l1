node .\scripts\HLC\resetScInfo.js

call npx hardhat run ./scripts/NativeTokenICKT/0_transfer_token.js

call npx hardhat run ./scripts/CustomERC20/0_deploy.js
call npx hardhat run ./scripts/CustomERC20/1_transfer_token.js

call npx hardhat run ./scripts/HLC/0_deploy_restrictions.js
call npx hardhat run ./scripts/HLC/1_deploy_commercial_paper.js

call npx hardhat run ./scripts/HLC/2_deploy_hlc.js

call npx hardhat run ./scripts/HLC/3_seller_transfer_token_to_hlc.js
call npx hardhat run ./scripts/HLC/4_buyer_transfer_token_to_hlc.js
call npx hardhat run ./scripts/HLC/5_execute_dvp.js