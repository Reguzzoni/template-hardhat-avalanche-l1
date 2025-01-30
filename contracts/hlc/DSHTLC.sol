// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.20;

import "./HLC.sol";

contract DSHTLC is HLC {
    //----------------------------------------//

    //----------------- STATE ----------------//

    //----------------------------------------//
    uint256 public VALIDATION_TIME;

    HLClib.StatusSign public sellerSign = HLClib.StatusSign.Empty;
    HLClib.StatusSign public buyerSign = HLClib.StatusSign.Empty;

    //----------------------------------------//

    //---------------- ERROR -----------------//

    //----------------------------------------//

    error ErrorValidationTime();

    //----------------------------------------//

    //--------------- MODIFIERS --------------//

    //----------------------------------------//

    modifier isBeforeOfValidationTime() {
        if (VALIDATION_TIME < block.timestamp) {
            revert ErrorValidationTime();
        }

        _;
    }

    modifier isAfterOfValidationTime() {
        if (block.timestamp < VALIDATION_TIME) {
            revert ErrorValidationTime();
        }

        _;
    }

    modifier alreadySignedBySeller() {
        if (sellerSign != HLClib.StatusSign.Signed) {
            revert InvalidSellerError();
        }

        _;
    }

    modifier alreadySignedByBuyer() {
        if (buyerSign != HLClib.StatusSign.Signed) {
            revert InvalidBuyerError();
        }

        _;
    }

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
        uint _expireTime,
        uint _validationTime
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
    {
        if (_validationTime < block.timestamp) {
            revert ErrorValidationTime();
        }

        if (_validationTime > _expireTime) {
            revert ErrorValidationTime();
        }

        VALIDATION_TIME = _validationTime;
    }

    // DEPOSIT
    function depositAssetToken()
        external
        onlySeller
        onlyInitialized
        notAlreadyDepositedAssetToken
        isNotExpired
        isBeforeOfValidationTime
        nonReentrant
    {
        _depositAssetToken();
    }

    function depositPaymentToken()
        external
        onlyBuyer
        onlyInitialized
        notAlreadyDepositedPaymentToken
        isNotExpired
        isBeforeOfValidationTime
        nonReentrant
    {
        _depositPaymentToken();
    }

    // WITHDRAW
    function withdrawAssetToken()
        external
        onlySeller
        onlyInitialized
        alreadyDepositedAssetToken
        isNotExpired
        isBeforeOfValidationTime
    {
        _withdrawAssetToken();
    }

    function withdrawPaymentToken()
        external
        onlyBuyer
        onlyInitialized
        alreadyDepositedPaymentToken
        isNotExpired
        isBeforeOfValidationTime
    {
        _withdrawPaymentToken();
    }

    // SIGN
    function sign()
        external
        onlyInitialized
        isNotExpired
        alreadyDepositedAssetToken
        alreadyDepositedPaymentToken
        isAfterOfValidationTime
        nonReentrant
    {
        HLClib.StatusSign _statusSign;
        if (msg.sender == SELLER) {
            _statusSign = sellerSign;
        } else if (msg.sender == BUYER) {
            _statusSign = buyerSign;
        }

        if (_statusSign == HLClib.StatusSign.Signed) {
            revert AlreadySignedError();
        }

        _statusSign = HLClib.StatusSign.Signed;

        if (msg.sender == SELLER) {
            sellerSign = HLClib.StatusSign.Signed;
        } else if (msg.sender == BUYER) {
            buyerSign = HLClib.StatusSign.Signed;
        }

        // check if sellerSign and buyerSign are Signed
        if (
            sellerSign == HLClib.StatusSign.Signed &&
            buyerSign == HLClib.StatusSign.Signed
        ) {
            executeDvP();
        }
    }

    // DVP
    function executeDvP()
        internal
        onlyInitialized
        alreadyDepositedAssetToken
        alreadyDepositedPaymentToken
        isNotExpired
        isAfterOfValidationTime
        alreadySignedByBuyer
        alreadySignedBySeller
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
