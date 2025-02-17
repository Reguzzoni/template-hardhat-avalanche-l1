// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./ILoanAsset.sol";
import "./LoanAssetLib.sol";

contract LoanAsset is ILoanAsset {
    /* LOAN DRAFT

    
    // TODO NEXT STEPS:
    REVIEW CODE
    CREATE TEST
    CREATE PROXY
    MULTIPLE LENDERS MAYBE?

    Lender and Borrowers: 
    The contract is deployed by a lender who sets the loan details, 
    including borrowers and their shares in the loan. 
     
    Borrowers are tracked by their status, share percentage, outstanding principal, and remaining coupons.

    Loan Types: Amortized and Bullet
    Interest Rate Type: Fixed and Floating
    Loan Status: Preliminary, Live, Matured, Closed
    Coupon Status: Unpaid, Paid
    Borrower Status: Active, Repaid, Defaulted, Anticipated

    Loan Issuance:
    The lender deploys the contract and sets the loan details, 
    including the loan name, issuance country, currency, total amount, 
    start date, maturity date, interest rate, loan type, 
    interest rate type, and coupon payment dates.

    TODO IMPORTANT: THE FLOATING INTEREST RATE MUST BE UPDATED MANUALLY FOR EACH COUPON SO
    ALL COUPON ARE NOT CREATED AT START, BUT THE INTEREST RATE CAN BE UPDATED CREATING NEW COUPONS 
    (OR UPDATING THE EXISTING ONES)
    TODO IMPORTANT: THE FIXED INTEREST RATE IS SET AT START FOR ALL COUPONS

    Borrowers are added with their share percentage in the loan.

    Loan Start:
    The lender can start the loan after the start date.

    Interest Rate Update:
    The lender can update the interest rate for floating interest rate loans.

    Coupon Payment:
    Borrowers can pay their coupons based on the payment date and amount.

    Principal Payment:
    Borrowers can pay the principal amount after the loan matures.

    Default:
    The lender can set a borrower's status to defaulted.

    Anticipate Payment:
    Borrowers can request to pay the loan early.

    Loan Maturity:
    The lender can set the loan status to matured after the maturity date.

    Loan Closure:
    The lender can close the loan after all borrowers have paid their outstanding principal and coupons.

    Withdraw Funds:
    The lender can withdraw the funds from the contract after the loan is closed.

    Pausing:
    The contract can be paused and unpaused by the lender.

    Access Control:
    The contract uses access control to restrict certain functions to the lender.

    Reentrancy Guard:
    The contract uses a reentrancy guard to prevent reentrancy attacks.

    Events:
    The contract emits events for 
    loan issuance, 
    interest rate updates, 
    loan start, 
    coupon payments,
    principal payments, 
    loan maturity, 
    and loan closure.

    // Coupon logic
    // - The borrower can pay the coupon only after the payment date has been reached.
    // - The coupon amount is calculated based on the outstanding principal amount.
    // - The borrower can pay the coupon amount to the contract.
    // - After the coupon is paid, IF AMORTIZED the outstanding principal amount is reduced by the coupon amount.
    // - The borrower's status is updated to repaid if all coupons are paid.


    */

    // ##################################################################
    // ############################ STATE ###############################
    // ##################################################################
    address public immutable LENDER;

    bytes32 public immutable NAME;
    bytes32 public immutable ISSUANCE_COUNTRY;
    bytes32 public immutable CURRENCY;

    uint256 public immutable TOTAL_AMOUNT;
    uint256 public immutable START_DATE; // loan start epoch time
    uint256 public immutable MATURITY_DATE; // maturity date loan epoch time
    uint256 public interestRate; // interest rate bps

    address[] public BORROWERS; // needed for iterations // TODO implementare il set profilato per renderlo immutabile?
    mapping(address => uint256) public BORROWERS_SHARE; // percentage of the shares // TODO implementare il set profilato per renderlo immutabile?
    mapping(address => LoanAssetLib.BorrowerStatus) public BORROWERS_STATUS; // TODO implementare il set profilato per renderlo immutabile?

    uint256 public immutable TOTAL_COUPON_NUMBER;
    mapping(uint256 => uint256) public COUPON_PAYMENT_DATES; // TODO implementare il set profilato per renderlo immutabile?

    mapping(address => mapping(uint256 => LoanAssetLib.CouponInfo))
        public borrowersCoupons; // TODO implementare il set profilato per renderlo immutabile?
    mapping(address => LoanAssetLib.OutstandingInfo)
        public borrowersOutstandingPrincipal; // principal amount remained to be paid by the borrower // TODO implementare il set profilato per renderlo immutabile?

    LoanAssetLib.LoanType public immutable LOAN_TYPE;
    LoanAssetLib.InterestRateType public immutable INTEREST_RATE_TYPE;
    LoanAssetLib.LoanStatus public currentLoanStatus;

    // until 0.8.24 solidity, use _locked to prevent reentrancy
    bool private _locked;

    // is paused flag
    bool private _isPaused;

    // ##################################################################
    // #################### REMOVED DEFAULT PAYMENT #####################
    // ##################################################################
    // receive() external payable {}

    // fallback() external payable {}

    // #####################################################################
    // ############################ MODIFIER ###############################
    // #####################################################################
    // Modifier allowing lender to perform actions
    modifier onlyOwner() {
        require(
            msg.sender == LENDER,
            "Only the lender can perform this action."
        );
        _;
    }

    // only enable borrower
    modifier onlyActiveBorrower() {
        require(
            BORROWERS_STATUS[msg.sender] == LoanAssetLib.BorrowerStatus.ACTIVE,
            "Only the lender can perform this action."
        );
        _;
    }

    // prevent reentrancy
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");

        _locked = true;

        _;

        _locked = false;

        // solc 0.8.24
        // assembly {
        //     if tload(0) {
        //         revert(0, 0)
        //     }
        //     tstore(0, 1)
        // }
        // _;
        // assembly {
        //     tstore(0, 0)
        // }
    }

    // modifier to check if the contract is paused
    modifier whenNotPaused() {
        require(!_isPaused, "Contract is paused");
        _;
    }

    // ##################################################################
    // ############################ EVENT ###############################
    // ##################################################################
    event Paused();
    event Unpaused();

    // ##################################################################
    // ######################### CONSTRUCTOR ############################
    // ##################################################################
    constructor(
        LoanAssetLib.LoanAnag memory _loanAnag,
        LoanAssetLib.LoanInfo memory _loanInfo
    ) {
        // TODO add REQUIRES on input parameters
        require(
            _loanInfo.totalAmount > 0,
            "Total amount must be greater than zero."
        );
        require(
            _loanInfo.borrowers.length == _loanInfo.borrowerShares.length,
            "Mismatch in borrowers and shares."
        );
        require(
            _loanAnag.startDate < _loanAnag.maturityDate,
            "Start date must be before maturity date."
        );

        LENDER = msg.sender;

        NAME = _loanAnag.name;
        ISSUANCE_COUNTRY = _loanAnag.issuanceCountry;
        CURRENCY = _loanAnag.currency;
        TOTAL_AMOUNT = _loanInfo.totalAmount;
        START_DATE = _loanAnag.startDate;
        MATURITY_DATE = _loanAnag.maturityDate;
        LOAN_TYPE = _loanAnag.loanType;
        INTEREST_RATE_TYPE = _loanAnag.interestRateType;
        TOTAL_COUPON_NUMBER = _loanInfo.couponPaymentDates.length;

        interestRate = _loanInfo.interestRate;

        // set coupon payment dates
        // TODO maybe make more sense only to set on FLOATING?
        uint256 couponsLength = _loanInfo.couponPaymentDates.length; // gas optimization
        for (
            uint256 couponPaymentIndex = 0;
            couponPaymentIndex < _loanInfo.couponPaymentDates.length;

        ) {
            COUPON_PAYMENT_DATES[couponPaymentIndex] = _loanInfo
                .couponPaymentDates[couponPaymentIndex];
            unchecked {
                couponPaymentIndex++;
            }
        }

        // set percentage of shares for each borrower and coupon
        uint256 borrowersLength = _loanInfo.borrowers.length; // gas optimization
        for (uint256 borrowerIndex = 0; borrowerIndex < borrowersLength; ) {
            address borrower = _loanInfo.borrowers[borrowerIndex];
            uint256 share = _loanInfo.borrowerShares[borrowerIndex];

            require(share > 0, "Borrower share must be greater than zero.");

            // set borrower status
            BORROWERS.push(borrower);
            BORROWERS_SHARE[borrower] = share;
            BORROWERS_STATUS[borrower] = LoanAssetLib.BorrowerStatus.ACTIVE;

            // set outstanding principal amount and coupon number left to pay
            borrowersOutstandingPrincipal[borrower] = LoanAssetLib
                .OutstandingInfo({
                    outstandingPrincipalAmount: (TOTAL_AMOUNT * share) / 100,
                    couponNumberLeftToPay: couponsLength
                });

            // if IR fixed, calculate coupon amount for each borrower and all next coupons
            if (
                _loanAnag.interestRateType ==
                LoanAssetLib.InterestRateType.FIXED
            ) {
                for (uint256 couponIndex = 0; couponIndex < couponsLength; ) {
                    // create coupons
                    borrowersCoupons[_loanInfo.borrowers[borrowerIndex]][
                        borrowerIndex
                    ] = _createNextCoupon(
                        _loanInfo.borrowers[borrowerIndex],
                        _loanInfo.couponPaymentDates[couponIndex]
                    );

                    unchecked {
                        couponIndex++;
                    }
                }
            } else if (
                _loanAnag.interestRateType ==
                LoanAssetLib.InterestRateType.FLOATING
            ) {
                // if floating and the IR must be inserted for each coupon manually, so set only the first one
                borrowersCoupons[_loanInfo.borrowers[borrowerIndex]][
                    borrowerIndex
                ] = _createNextCoupon(
                    _loanInfo.borrowers[borrowerIndex],
                    _loanInfo.couponPaymentDates[0]
                );
            } else {
                revert("Invalid interest rate type.");
            }

            unchecked {
                borrowerIndex++;
            }
        }

        currentLoanStatus = LoanAssetLib.LoanStatus.PRELIMINARY;

        emit LoanAssetLib.LoanIssued(NAME, LENDER, TOTAL_AMOUNT);
    }

    // ###############################################################
    // ######################### FUNCTION ############################
    // ###############################################################

    // pause contract
    function pause() external onlyOwner {
        _isPaused = true;
        emit Paused();
    }

    // unpause contract
    function unpause() external onlyOwner {
        _isPaused = false;
        emit Unpaused();
    }

    // create next coupon
    function _createNextCoupon(
        address _borrower,
        uint256 _paymentDate
    ) private view returns (LoanAssetLib.CouponInfo memory couponInfo) {
        return
            LoanAssetLib.CouponInfo({
                amount: _calculateNextAmountByBorrower(_borrower),
                paymentDate: _paymentDate,
                couponStatus: LoanAssetLib.CouponStatus.UNPAID
            });
    }

    // calculate amount to pay based on outstanding
    function _calculateNextAmountByBorrower(
        address borrower
    ) private view returns (uint256) {
        LoanAssetLib.OutstandingInfo
            memory borrowerOutstandingInfo = borrowersOutstandingPrincipal[
                borrower
            ];

        uint256 interestMatured = (borrowerOutstandingInfo
            .outstandingPrincipalAmount * interestRate) / 100; // interest
        if (LoanAssetLib.LoanType.AMORTIZED == LOAN_TYPE) {
            return
                borrowerOutstandingInfo.outstandingPrincipalAmount +
                interestMatured; // principal // interest
        } else if (LoanAssetLib.LoanType.BULLET == LOAN_TYPE) {
            return interestMatured; // interest
        } else {
            revert("Invalid loan type.");
        }
    }

    function calculateNextCoupon() public view returns (uint256) {
        return _calculateNextAmountByBorrower(msg.sender);
    }

    // Over the start date, the loan can be started
    // TODO the issuer can decide the IR for the first coupon on the start date?
    function setLoanStart() external nonReentrant onlyOwner {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatus.PRELIMINARY,
            "Loan is not in preliminary state!"
        );
        currentLoanStatus = LoanAssetLib.LoanStatus.LIVE;

        emit LoanAssetLib.LoanStarted();
    }

    // set interest rate
    function updateInterestRateAndCoupon(
        uint256 _interestRate
    ) external nonReentrant onlyOwner {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatus.PRELIMINARY,
            "Loan is not in preliminary state!"
        );

        require(_interestRate > 0, "Interest rate must be greater than zero.");

        require(
            INTEREST_RATE_TYPE == LoanAssetLib.InterestRateType.FLOATING,
            "Interest rate type must be floating."
        );

        interestRate = _interestRate;

        // set next coupon amount for each borrower
        uint256 borrowersLength = BORROWERS.length; // gas optimization
        for (uint256 borrowersIndex = 0; borrowersIndex < borrowersLength; ) {
            address borrower = BORROWERS[borrowersIndex];

            LoanAssetLib.OutstandingInfo
                memory borrowerOutstandingInfo = borrowersOutstandingPrincipal[
                    borrower
                ];

            uint256 nextCouponIndex = TOTAL_COUPON_NUMBER -
                borrowerOutstandingInfo.couponNumberLeftToPay +
                1; // gas optimization

            // if someone has already paid all the coupons, skip
            if (nextCouponIndex >= TOTAL_COUPON_NUMBER) {
                continue;
            }

            borrowersCoupons[BORROWERS[borrowersIndex]][
                nextCouponIndex
            ] = LoanAssetLib.CouponInfo({
                amount: _calculateNextAmountByBorrower(
                    BORROWERS[borrowersIndex]
                ),
                paymentDate: COUPON_PAYMENT_DATES[nextCouponIndex],
                couponStatus: LoanAssetLib.CouponStatus.UNPAID
            });

            unchecked {
                borrowersIndex++;
            }
        }

        emit LoanAssetLib.UpdateInterestRateAndCoupon(_interestRate);
    }

    // Borrower request to pay a coupon
    function payCoupon(
        uint256 couponNumber
    ) external payable nonReentrant onlyActiveBorrower {
        // check loan status
        require(
            currentLoanStatus == LoanAssetLib.LoanStatus.LIVE,
            "Loan is not live."
        );

        LoanAssetLib.OutstandingInfo
            memory borrowerOutstandingInfo = borrowersOutstandingPrincipal[
                msg.sender
            ];

        // check coupon number
        require(
            borrowerOutstandingInfo.couponNumberLeftToPay == 0,
            "No coupon left to pay"
        );
        require(couponNumber < TOTAL_COUPON_NUMBER, "Invalid coupon number.");

        LoanAssetLib.CouponInfo storage couponInfo = borrowersCoupons[
            msg.sender
        ][couponNumber];

        // check on coupon status
        require(
            couponInfo.couponStatus == LoanAssetLib.CouponStatus.UNPAID,
            "Coupon has already been paid."
        );
        require(
            couponInfo.paymentDate <= block.timestamp,
            "Coupon payment date has not been reached yet."
        );

        // check on amount
        uint256 couponAmount = _calculateNextAmountByBorrower(msg.sender);
        require(couponAmount != 0, "Coupon must be defined before being paid.");
        require(msg.value == couponAmount, "Incorrect coupon amount sent.");

        // update outstanding info
        if (LoanAssetLib.LoanType.AMORTIZED == LOAN_TYPE) {
            borrowerOutstandingInfo.outstandingPrincipalAmount -= couponAmount;
        }
        borrowerOutstandingInfo.couponNumberLeftToPay--;

        // update coupon status
        couponInfo.couponStatus = LoanAssetLib.CouponStatus.PAID;

        // payment from msg.sender to smart contract on the payable function
        // TODO ERC20 transfer

        emit LoanAssetLib.CouponPaid(msg.sender, couponAmount, couponNumber);
    }

    // Pay principal
    function payPrincipal() external payable nonReentrant onlyActiveBorrower {
        // check loan status
        require(
            currentLoanStatus == LoanAssetLib.LoanStatus.MATURED,
            "Loan is not matured."
        );

        uint principalAmount = _calculateNextAmountByBorrower(msg.sender);
        require(
            principalAmount != 0,
            "No outstanding principal amount to pay."
        );

        LoanAssetLib.OutstandingInfo
            memory borrowerOutstandingInfo = borrowersOutstandingPrincipal[
                msg.sender
            ];

        require(
            borrowerOutstandingInfo.outstandingPrincipalAmount != 0,
            "No outstanding principal amount to pay."
        );
        require(
            msg.value == borrowerOutstandingInfo.outstandingPrincipalAmount,
            "Incorrect principal amount sent."
        );

        // update outstanding principal amount and coupon number left to pay
        borrowerOutstandingInfo.outstandingPrincipalAmount = 0;
        borrowerOutstandingInfo.couponNumberLeftToPay = 0;

        // update borrower status
        BORROWERS_STATUS[msg.sender] = LoanAssetLib.BorrowerStatus.REPAID;

        // payment from msg.sender to smart contract on the payable function
        // TODO ERC20 transfer

        emit LoanAssetLib.LoanRepaid(msg.sender, msg.value);
    }

    function setDefault(address borrower) external nonReentrant onlyOwner {
        require(
            BORROWERS_STATUS[borrower] == LoanAssetLib.BorrowerStatus.ACTIVE,
            "Borrower is not active."
        );

        BORROWERS_STATUS[borrower] = LoanAssetLib.BorrowerStatus.DEFAULTED;
    }

    function enableAnticipatePayment(
        address borrower
    ) external nonReentrant onlyOwner {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatus.LIVE,
            "Loan must be live to anticipate payment."
        );

        require(
            BORROWERS_STATUS[borrower] == LoanAssetLib.BorrowerStatus.ACTIVE,
            "Borrower is not active to anticipate payment."
        );

        // check borrower outstanding
        LoanAssetLib.OutstandingInfo
            memory borrowerOutstandingInfo = borrowersOutstandingPrincipal[
                borrower
            ];

        require(
            borrowerOutstandingInfo.outstandingPrincipalAmount != 0 &&
                borrowerOutstandingInfo.couponNumberLeftToPay != 0,
            "No outstanding principal amount or coupon left to pay."
        );

        BORROWERS_STATUS[msg.sender] = LoanAssetLib.BorrowerStatus.ANTICIPATED;
    }

    function disableAnticipatePayment(
        address borrower
    ) external nonReentrant onlyOwner {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatus.LIVE,
            "Loan must be live to anticipate payment."
        );

        require(
            BORROWERS_STATUS[borrower] ==
                LoanAssetLib.BorrowerStatus.ANTICIPATED,
            "Borrower is not enabled to anticipate payment."
        );

        BORROWERS_STATUS[msg.sender] = LoanAssetLib.BorrowerStatus.ACTIVE;
    }

    function anticipatePayment() external payable {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatus.LIVE,
            "Loan must be live to anticipate payment."
        );

        require(
            BORROWERS_STATUS[msg.sender] ==
                LoanAssetLib.BorrowerStatus.ANTICIPATED,
            "Borrower is not enabled to anticipate payment."
        );

        address borrower = msg.sender;

        LoanAssetLib.OutstandingInfo
            memory borrowerOutstandingInfo = borrowersOutstandingPrincipal[
                borrower
            ];

        uint256 paymentAmount = _calculateNextAmountByBorrower(borrower);

        require(
            msg.value >= paymentAmount,
            "Insufficient funds to anticipate payment."
        );

        // update outstanding principal amount and coupon number left to pay
        borrowerOutstandingInfo.outstandingPrincipalAmount = 0;
        borrowerOutstandingInfo.couponNumberLeftToPay = 0;

        // update borrower status
        BORROWERS_STATUS[borrower] = LoanAssetLib.BorrowerStatus.REPAID;

        // payment from msg.sender to smart contract on the payable function
        // TODO ERC20 transfer

        emit LoanAssetLib.LoanRepaid(borrower, paymentAmount);
    }

    // set loan matured request
    function setLoanMatured() external nonReentrant onlyOwner {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatus.LIVE,
            "Loan must be live to close it."
        );
        require(block.timestamp >= MATURITY_DATE, "Loan has not matured yet.");
        currentLoanStatus = LoanAssetLib.LoanStatus.MATURED;

        emit LoanAssetLib.LoanMatured();
    }

    // close loan request
    function setLoanClosed() external nonReentrant onlyOwner {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatus.MATURED,
            "Loan must be matured before closing."
        );

        // check each borrower paid outstanding principal amount (so implicit coupons)
        uint256 borrowersLength = BORROWERS.length; // gas optimization
        for (uint256 borrowersIndex = 0; borrowersIndex < borrowersLength; ) {
            // BUT if some borrower is set to DEFAULTED, skip
            if (
                BORROWERS_STATUS[BORROWERS[borrowersIndex]] ==
                LoanAssetLib.BorrowerStatus.DEFAULTED
            ) {
                unchecked {
                    borrowersIndex++;
                }
                continue;
            }

            // if some borrower has not paid all the coupons, revert
            require(
                borrowersOutstandingPrincipal[BORROWERS[borrowersIndex]]
                    .couponNumberLeftToPay == 0,
                "All borrowers must pay all coupons before closing."
            );
            unchecked {
                borrowersIndex++;
            }
        }

        currentLoanStatus = LoanAssetLib.LoanStatus.CLOSED;
    }

    function withdrawFunds() external nonReentrant onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}
