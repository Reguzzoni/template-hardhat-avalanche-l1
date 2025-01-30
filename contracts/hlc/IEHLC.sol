// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.20;

import "./HLC.sol";

contract IEHLC is HLC {
    //----------------------------------------//

    //--------------- FALLBACKS --------------//

    //----------------------------------------//

    /// @dev Fallback function

    /// Receive and fallback aren't implemented to reject any incoming ether

    //----------------------------------------//

    //--------------- FUNCTIONS --------------//

    //----------------------------------------//

    constructor(
        address _seller,
        address _buyer,
        string memory _price,
        uint _assetTokenAmount,
        uint _paymentTokenAmount,
        bytes memory _tipsId,
        address _assetTokenAddress,
        address _paymentTokenAddress,
        uint _expireTime
    )
        HLC(
            _seller,
            _buyer,
            _price,
            _assetTokenAmount,
            _paymentTokenAmount,
            _tipsId,
            _assetTokenAddress,
            _paymentTokenAddress,
            _expireTime
        )
    {}

    // DEPOSIT
    function depositAssetToken()
        external
        onlySeller
        onlyInitialized
        notAlreadyDepositedAssetToken
        isNotExpired
    {
        _depositAssetToken();

        // check if assetLegStatus and payLegStatus is Deposited
        if (
            assetLegStatus == HLClib.StatusLeg.Deposited &&
            paymentLegStatus == HLClib.StatusLeg.Deposited
        ) {
            executeDvP();
        }
    }

    function depositPaymentToken()
        external
        onlyBuyer
        onlyInitialized
        notAlreadyDepositedPaymentToken
        isNotExpired
    {
        _depositPaymentToken();

        // check if assetLegStatus and payLegStatus is Deposited
        if (
            assetLegStatus == HLClib.StatusLeg.Deposited &&
            paymentLegStatus == HLClib.StatusLeg.Deposited
        ) {
            executeDvP();
        }
    }

    // WITHDRAW
    function withdrawAssetToken()
        external
        onlySeller
        onlyInitialized
        alreadyDepositedAssetToken
        isNotExpired
    {
        _withdrawAssetToken();
    }

    function withdrawPaymentToken()
        external
        onlyBuyer
        onlyInitialized
        alreadyDepositedPaymentToken
        isNotExpired
    {
        _withdrawPaymentToken();
    }

    // DVP
    function executeDvP()
        internal
        onlyInitialized
        alreadyDepositedAssetToken
        alreadyDepositedPaymentToken
        isNotExpired
    {
        // update status
        hlcStatus = HLClib.StatusHLC.Executed;

        // execute transfer to the buyer
        bool success = ASSET_TOKEN.transfer(BUYER, ASSET_TOKEN_AMOUNT);

        if (!success) {
            revert FailedTransferError();
        }

        // execute payment to the seller
        success = PAYMENT_TOKEN.transfer(SELLER, PAYMENT_TOKEN_AMOUNT);

        if (!success) {
            revert FailedTransferError();
        }

        // issue event
        emit HLClib.Execution(SELLER, BUYER);
    }
}
