// SPDX-License-Identifier: CC0-1.0



pragma solidity ^0.8.0;

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

    bytes32 public immutable HASH_EXECUTION_KEY; // <-- hash_execution_key to force execution

    bytes32 public immutable HASH_CANCELLATION_KEY; // <-- hash_cancellation_key to force cancellation

    HLClib.Status public hlcStatus;



    //-------------------------------------//

    //--------------- TOKEN ---------------//

    //-------------------------------------//

    SecurityAsset public immutable TOKEN;

    uint public immutable TOKEN_AMOUNT;



    //----------------------------------------//

    //---------------- ERRORS ----------------//

    //----------------------------------------//

    error InvalidSenderError();

    error InvalidSellerError();

    error InvalidBuyerError();

    error InvalidTokenError();

    error StatusNotInizializedError();

    error SellerAndBuyerAreSameError();

    error InvalidCancellationKeyError();

    error InvalidTokenAmountError();

    error InvalidPriceError();



    error InvalidExecutionKeyError();

    error InvalidCancellationKey();

    

    error FailedTransferError();

    error SellerInsufficientFundsError();



    //----------------------------------------//

    //--------------- MODIFIERS --------------//

    //----------------------------------------//



    modifier onlySeller() {

        if(msg.sender != SELLER) {

            revert InvalidSellerError();

        }

        _;

    }



    modifier onlyBuyer() {

        if(msg.sender != BUYER) {

            revert InvalidBuyerError();

        }

        _;

    }



    modifier onlyInitialized() {

        if(hlcStatus != HLClib.Status.Inizialized) {

            revert StatusNotInizializedError();

        }

        _;

    }



    //------------------------------------------//

    //--------------- CONSTRUCTOR --------------//

    //------------------------------------------//



    /// @dev Initializes a new instance of the HLC (Hash Link Contract) contract.

    /// @param _seller The address of the seller participating in the DvP.

    /// @param _buyer The address of the buyer participating in the DvP.

    /// @param _price The agreed price of the security token in euro.

    /// @param _tokenAmount The amount of security tokens to be exchanged.

    /// @param _tipsId An identifier used by tips associated with the DvP.

    /// @param _hashExecutionKey The hashed execution key required for forced execution.

    /// @param _hashCancellationKey The hashed cancellation key required for forced cancellation.

    /// @param _tokenAddress The address of the security token that represents the security token.

    ///

    /// Requirements:

    /// - The master address cannot be zero and cannot be the seller or the buyer.

    /// - The seller's address cannot be zero.

    /// - The buyer's address cannot be zero and must be different from the seller's address.

    /// - The hashExecutionKey cannot be empty.

    /// - The hashCancellationKey cannot be empty.

    /// - The token address cannot be zero.

    /// - The seller must have at least one token balance.

    /// - The price cannot be empty.

    ///

    /// Effects:

    /// - Sets all the contract's state variables.

    /// - Sets the contract status to "Initialized".

    ///

    /// Emits:

    /// - "Initialized" event with the contract details.

    constructor(

        address _seller,

        address _buyer,

        string memory _price,

        uint _tokenAmount,

        bytes memory _tipsId,

        bytes32 _hashExecutionKey,

        bytes32 _hashCancellationKey,

        address _tokenAddress

    ) {

        // check address

        if(msg.sender == address(0) || msg.sender == _seller) {

            revert InvalidSenderError();

        }

        if(_seller == address(0)) {

            revert InvalidSellerError();

        }

        if(_buyer == address(0)) {

            revert InvalidBuyerError();

        }

        if (_seller == _buyer) {

            revert SellerAndBuyerAreSameError();

        }

        

        // implicitly check _buyer != msg.sender



        if(_tokenAddress == address(0)) {

            revert InvalidTokenError();

        }



        // check hlc info

        if(bytes(_price).length == 0) {

            revert InvalidPriceError();

        }

        if(_hashExecutionKey.length == 0) {

            revert InvalidExecutionKeyError();

        }

        if(_hashCancellationKey.length == 0) {

            revert InvalidCancellationKeyError();

        }

        if(_tokenAmount == 0) {

            revert InvalidTokenAmountError();

        }



        // check funds

        TOKEN = SecurityAsset(_tokenAddress);

        if(TOKEN.balanceOf(_seller) < _tokenAmount) {

            revert SellerInsufficientFundsError();

        }



        // assignments

        MASTER = msg.sender;

        SELLER = _seller;

        BUYER = _buyer;

        PRICE = _price;

        TOKEN_AMOUNT = _tokenAmount;

        TIPS_ID = _tipsId;

        HASH_EXECUTION_KEY = _hashExecutionKey;

        HASH_CANCELLATION_KEY = _hashCancellationKey;

        hlcStatus = HLClib.Status.Inizialized;



        // issue event

        emit HLClib.Initialized(

            SELLER,

            BUYER,

            PRICE,

            TOKEN_AMOUNT,

            TIPS_ID,

            _tokenAddress

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



    ///

    /// @dev Allows the seller to execute the cooperative execution of the DvP.

    ///

    /// Requirements:

    /// - Only the seller can call this function.

    /// - The HLC must be in the 'Initialized' status.

    ///

    /// Effects:

    /// - Transfers N security token from the seller to the buyer.

    /// - Updates the HLC status to 'Executed'.

    ///

    /// Emits:

    /// - 'CooperativeExecution' event with the seller and buyer addresses.

    ///

    function cooperativeExecution() external onlySeller onlyInitialized {

        // update status

        hlcStatus = HLClib.Status.Executed;



        // execute transfer to the buyer

        bool success = TOKEN.transfer(BUYER, TOKEN_AMOUNT);

        if(!success) {

            revert FailedTransferError();

        }



        // issue event

        emit HLClib.CooperativeExecution(SELLER, BUYER);

    }



    /// @dev Allows the buyer to cancel the DvP cooperatively.

    ///

    /// Requirements:

    /// - Only the buyer can call this function.

    /// - The HLC must be in the 'Initialized' status.

    ///

    /// Effects:

    /// - Transfers N security token from the buyer to the seller.

    /// - Updates the HLC status to 'Cancelled'.

    ///

    /// Emits:

    /// - 'CooperativeCancellation' event with the buyer and seller addresses.

    function cooperativeCancellation() external onlyBuyer onlyInitialized {

        // update status

        hlcStatus = HLClib.Status.Cancelled;

        

        // execute transfer to the seller

        bool success = TOKEN.transfer(SELLER, TOKEN_AMOUNT);

        if(!success) {

            revert FailedTransferError();

        }

        

        // issue event

        emit HLClib.CooperativeCancellation(BUYER, SELLER);

    }



    /// @dev Allows to force the execution of the DvP by the buyer.

    /// This function can only be called by the buyer when the HLC is in the 'Initialized' status.

    /// The execution is forced by providing the `_executionKey` as a parameter, which will be validated against the stored hash.

    ///

    /// @param _executionKey The execution key provided by the buyer.

    ///

    /// Requirements:

    /// - The caller must be the buyer of the HLC.

    /// - The HLC must be in the 'Initialized' status.

    /// - The provided `_executionKey` must match the stored hashExecutionKey.

    ///

    /// Effects:

    /// - Transfers TOKEN_AMOUNT security token from the buyer to the seller.

    /// - Updates the status of the HLC to 'Executed'.

    ///

    /// Emits:

    /// - 'ForcedExecution' event with the buyer and seller addresses.

    function forceExecution(

        string memory _executionKey

    ) external onlyBuyer onlyInitialized {

        // check execution key

        if ( HASH_EXECUTION_KEY != sha256(abi.encodePacked(_executionKey))) {

            revert InvalidExecutionKeyError();

        }



        // update status

        hlcStatus = HLClib.Status.Executed;



        // execute transfer to the seller

        bool success = TOKEN.transfer(BUYER, TOKEN_AMOUNT);

        if(!success) {

            revert FailedTransferError();

        }



        // issue event

        emit HLClib.ForcedExecution(BUYER, SELLER);

    }



    /// @dev Allows to force the cancellation of the DvP by the seller.

    /// This function can only be called by the seller when the HLC is in the 'Initialized' status.

    /// The cancellation is forced by providing the `_cancellationKey` as a parameter, which will be validated against the stored hash.

    ///

    /// @param _cancellationKey The cancellation key provided by the seller.

    ///

    /// Requirements:

    /// - The caller must be the seller of the HLC.

    /// - The HLC must be in the 'Initialized' status.

    /// - The provided `_cancellationKey` must match the stored hashCancellationKey.

    ///

    /// Effects:

    /// - Transfers TOKEN_AMOUNT security token from the seller to the buyer.

    /// - Updates the status of the HLC to 'Cancelled'.

    ///

    /// Emits:

    /// - 'ForcedCancellation' event with the seller and buyer addresses.

    function forceCancellation(

        string memory _cancellationKey

    ) external onlySeller onlyInitialized {

        // check cancellation key

        if (HASH_CANCELLATION_KEY != sha256(abi.encodePacked(_cancellationKey))) {

            revert InvalidCancellationKey();

        }



        // update status

        hlcStatus = HLClib.Status.Cancelled;



        // execute transfer to the buyer

        bool success = TOKEN.transfer(SELLER, TOKEN_AMOUNT);

        if(!success) {

            revert FailedTransferError();

        }



        // issue event

        emit HLClib.ForcedCancellation(SELLER, BUYER);

    }

}
