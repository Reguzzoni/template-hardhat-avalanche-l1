// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.20;

import "./SecurityAsset.sol";

import "./lib/HLClib.sol";

/// @title HLC (Hash Link Contract)

/// @dev A contract that facilitates Delivery versus Payment (DvP) transactions using hash-linked contracts.

contract HLC {
    //-------------------------------------//

    //--------------- STATE ---------------//

    //-------------------------------------//

    address public immutable MASTER;

    address public immutable SELLER;

    address public immutable BUYER;

    string public PRICE; // <-- price off chain offered by the buyer

    bytes public TIPS_ID; // <-- tips_trx_id tip environment

    uint public immutable EXPIRE_TIME; // <-- expire time

    HLClib.StatusHLC public hlcStatus;
    HLClib.StatusAssetLeg public assetLegStatus;
    HLClib.StatusPaymentLeg public paymentLegStatus;

    //-------------------------------------//

    //--------------- TOKEN ---------------//

    //-------------------------------------//

    SecurityAsset public immutable ASSET_TOKEN;
    ERC20 public immutable PAYMENT_TOKEN;

    uint public immutable ASSET_TOKEN_AMOUNT;
    uint public immutable PAYMENT_TOKEN_AMOUNT;

    //----------------------------------------//

    //---------------- ERRORS ----------------//

    //----------------------------------------//

    error InvalidSenderError();

    error InvalidSellerError();

    error InvalidBuyerError();

    error InvalidTokenError();

    error StatusNotInizializedError();

    error StatusAlreadyDepositedError();

    error ExpiredError();

    error InvalidMasterError();

    error StatusNotAlreadyDepositedError();

    error SellerAndBuyerAreSameError();

    error InvalidCancellationKeyError();

    error InvalidTokenAmountError();

    error InvalidExpireTimeError();

    error InvalidPriceError();

    error FailedTransferError();

    error SellerInsufficientFundsError();

    error BuyerInsufficientFundsError();

    //----------------------------------------//

    //--------------- MODIFIERS --------------//

    //----------------------------------------//

    modifier onlySeller() {
        if (msg.sender != SELLER) {
            revert InvalidSellerError();
        }

        _;
    }

    modifier onlyBuyer() {
        if (msg.sender != BUYER) {
            revert InvalidBuyerError();
        }

        _;
    }

    modifier onlyInitialized() {
        if (hlcStatus != HLClib.StatusHLC.Inizialized) {
            revert StatusNotInizializedError();
        }

        _;
    }

    modifier notAlreadyDepositedAssetToken() {
        if (assetLegStatus == HLClib.StatusAssetLeg.Deposited) {
            revert StatusAlreadyDepositedError();
        }

        _;
    }

    modifier alreadyDepositedAssetToken() {
        if (assetLegStatus != HLClib.StatusAssetLeg.Deposited) {
            revert StatusAlreadyDepositedError();
        }

        _;
    }

    modifier notAlreadyDepositedPaymentToken() {
        if (paymentLegStatus == HLClib.StatusPaymentLeg.Deposited) {
            revert StatusAlreadyDepositedError();
        }

        _;
    }

    modifier alreadyDepositedPaymentToken() {
        if (paymentLegStatus != HLClib.StatusPaymentLeg.Deposited) {
            revert StatusAlreadyDepositedError();
        }

        _;
    }

    modifier isNotExpired() {
        if (block.timestamp > EXPIRE_TIME) {
            revert ExpiredError();
        }

        _;
    }

    modifier isMaster() {
        if (MASTER != msg.sender) {
            revert InvalidMasterError();
        }

        _;
    }

    constructor(
        address _seller,
        address _buyer,
        string memory _price,
        uint _assetTokenAmount,
        uint _paymentTokenAmount,
        bytes memory _tipsId,
        address _assetTokenAddress,
        address _paymentTokenAddress,
        uint expireTime
    ) {
        // check address
        if (msg.sender == address(0) || msg.sender == _seller) {
            revert InvalidSenderError();
        }

        if (_seller == address(0)) {
            revert InvalidSellerError();
        }

        if (_buyer == address(0)) {
            revert InvalidBuyerError();
        }

        if (_seller == _buyer) {
            revert SellerAndBuyerAreSameError();
        }

        // implicitly check _buyer != msg.sender
        if (_assetTokenAddress == address(0)) {
            revert InvalidTokenError();
        }

        if (_paymentTokenAddress == address(0)) {
            revert InvalidTokenError();
        }

        // check hlc info

        if (bytes(_price).length == 0) {
            revert InvalidPriceError();
        }

        if (_assetTokenAmount == 0) {
            revert InvalidTokenAmountError();
        }

        if (_paymentTokenAmount == 0) {
            revert InvalidTokenAmountError();
        }

        if (expireTime == 0 || expireTime < block.timestamp) {
            revert InvalidExpireTimeError();
        }

        // check funds
        ASSET_TOKEN = SecurityAsset(_assetTokenAddress);

        if (ASSET_TOKEN.balanceOf(_seller) < _assetTokenAmount) {
            revert SellerInsufficientFundsError();
        }

        PAYMENT_TOKEN = ERC20(_paymentTokenAddress);

        if (PAYMENT_TOKEN.balanceOf(_buyer) < _paymentTokenAmount) {
            revert BuyerInsufficientFundsError();
        }

        // assignments
        MASTER = msg.sender;

        SELLER = _seller;

        BUYER = _buyer;

        PRICE = _price;

        ASSET_TOKEN_AMOUNT = _assetTokenAmount;

        PAYMENT_TOKEN_AMOUNT = _paymentTokenAmount;

        TIPS_ID = _tipsId;

        hlcStatus = HLClib.StatusHLC.Inizialized;

        EXPIRE_TIME = expireTime;

        // issue event

        emit HLClib.Initialized(
            SELLER,
            BUYER,
            PRICE,
            ASSET_TOKEN_AMOUNT,
            PAYMENT_TOKEN_AMOUNT,
            TIPS_ID,
            _assetTokenAddress,
            _paymentTokenAddress
        );
    }

    //----------------------------------------//

    //--------------- FALLBACKS --------------//

    //----------------------------------------//

    /// @dev Fallback function

    /// Receive and fallback aren't implemented to reject any incoming ether

    //----------------------------------------//

    //--------------- FUNCTIONS --------------//

    //----------------------------------------//

    // WITHDRAW
    function withdrawAssetToken()
        external
        onlySeller
        onlyInitialized
        alreadyDepositedAssetToken
    {
        // update status
        assetLegStatus = HLClib.StatusAssetLeg.Empty;

        // execute transfer to the seller
        bool success = ASSET_TOKEN.transfer(SELLER, ASSET_TOKEN_AMOUNT);

        if (!success) {
            revert FailedTransferError();
        }

        // issue event
        emit HLClib.AssetTokenWithdrawn(
            msg.sender,
            address(ASSET_TOKEN),
            ASSET_TOKEN_AMOUNT
        );
    }

    function withdrawPaymentToken()
        external
        onlyBuyer
        onlyInitialized
        alreadyDepositedPaymentToken
    {
        // update status
        paymentLegStatus = HLClib.StatusPaymentLeg.Empty;

        // execute transfer to the buyer
        bool success = PAYMENT_TOKEN.transfer(BUYER, PAYMENT_TOKEN_AMOUNT);

        if (!success) {
            revert FailedTransferError();
        }

        // issue event
        emit HLClib.PaymentTokenWithdrawn(
            msg.sender,
            address(PAYMENT_TOKEN),
            PAYMENT_TOKEN_AMOUNT
        );
    }

    // DEPOSIT
    function depositAssetToken()
        external
        onlySeller
        onlyInitialized
        notAlreadyDepositedAssetToken
        isNotExpired
    {
        // update status
        assetLegStatus = HLClib.StatusAssetLeg.Deposited;

        // execute transfer to the buyer
        bool success = ASSET_TOKEN.transferFrom(
            msg.sender,
            address(this),
            ASSET_TOKEN_AMOUNT
        );

        if (!success) {
            revert FailedTransferError();
        }

        // issue event
        emit HLClib.AssetTokenDeposited(
            msg.sender,
            address(ASSET_TOKEN),
            ASSET_TOKEN_AMOUNT
        );
    }

    function depositPaymentToken()
        external
        onlyBuyer
        onlyInitialized
        notAlreadyDepositedPaymentToken
        isNotExpired
    {
        // update status
        paymentLegStatus = HLClib.StatusPaymentLeg.Deposited;

        // execute transfer to the seller
        bool success = PAYMENT_TOKEN.transferFrom(
            msg.sender,
            address(this),
            PAYMENT_TOKEN_AMOUNT
        );

        if (!success) {
            revert FailedTransferError();
        }

        // issue event
        emit HLClib.PaymentTokenDeposited(
            msg.sender,
            address(PAYMENT_TOKEN),
            PAYMENT_TOKEN_AMOUNT
        );
    }

    function executeDvP()
        external
        onlyInitialized
        alreadyDepositedAssetToken
        alreadyDepositedPaymentToken
        isNotExpired
        isMaster
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
