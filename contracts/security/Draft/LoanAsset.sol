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
     
    Borrowers are tracked by their status, share percentage, outstanding principal, and remaining repayments.

    Loan Types: Amortized and Bullet
    Interest Rate Type: Fixed and Floating
    Loan Status: Preliminary, Live, Matured, Closed
    Repayment Status: Unpaid, Paid
    Borrower Status: Active, Repaid, Defaulted, Anticipated

    Loan Issuance:
    The lender deploys the contract and sets the loan details, 
    including the loan name, issuance country, currency, total amount, 
    start date, maturity date, interest rate, loan type, 
    interest rate type, and repayment dates.

    TODO IMPORTANT: THE FLOATING INTEREST RATE MUST BE UPDATED MANUALLY FOR EACH REPAYMENT SO
    ALL REPAYMENT ARE NOT CREATED AT START, BUT THE INTEREST RATE CAN BE UPDATED CREATING NEW REPAYMENTS 
    (OR UPDATING THE EXISTING ONES)
    TODO IMPORTANT: THE FIXED INTEREST RATE IS SET AT START FOR ALL REPAYMENTS

    Borrowers are added with their share percentage in the loan.

    Loan Start:
    The lender can start the loan after the start date.

    Interest Rate Update:
    The lender can update the interest rate for floating loans.

    Repayments:
    Borrowers can pay their repayments based on the payment date and amount.

    Principal Payment:
    Borrowers can pay the principal amount after the loan matures.

    Default:
    The lender can set a borrower's status to defaulted.

    Anticipate Payment:
    Borrowers can request to pay the loan early.

    Loan Maturity:
    The lender can set the loan status to matured after the maturity date.

    Loan Closure:
    The lender can close the loan after all borrowers have paid their outstanding principal and repayments.

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
    repayments,
    principal payments, 
    loan maturity, 
    and loan closure.

    // Repayment logic
    // - The borrower can pay the repayment only after the payment date has been reached.
    // - The Repayment amount is calculated based on the outstanding principal amount.
    // - The borrower can pay the Repayment amount to the contract.
    // - After the Repayment is paid, IF AMORTIZED the outstanding principal amount is reduced by the Repayment amount.
    // - The borrower's status is updated to repaid if all Repayments are paid.


    */

    // ##################################################################
    // ############################ STATE ###############################
    // ##################################################################
    address public immutable ISSUER;

    bytes32 public immutable NAME;
    bytes32 public immutable ISSUANCE_COUNTRY;
    bytes32 public immutable CURRENCY;

    uint256 public immutable TOTAL_AMOUNT;
    uint256 public immutable START_DATE; // loan start epoch time
    uint256 public immutable MATURITY_DATE; // maturity date loan epoch time
    uint256 public interestRate; // interest rate bps

    // LENDER
    address[] public LENDERS; // needed for iterations
    mapping(address => uint256) public LENDERS_SHARES; // percentage of the shares
    mapping(address => LoanAssetLib.LenderStatusEnum) public LENDERS_STATUS;

    // BORROWER
    address[] public BORROWERS; // needed for iterations
    mapping(address => uint256) public BORROWERS_SHARES; // percentage of the shares
    mapping(address => LoanAssetLib.BorrowerStatusEnum) public BORROWERS_STATUS;

    uint256 public immutable TOTAL_REPAYMENT_NUMBER;
    mapping(uint256 => uint256) public REPAYMENTS_DATES;

    mapping(address => mapping(uint256 => LoanAssetLib.RepaymentInfo))
        public borrowersRepayments; // repayment info for each borrower
    mapping(address => LoanAssetLib.OutstandingInfo)
        public borrowersOutstandingPrincipals; // principal amount remained to be paid by the borrower

    LoanAssetLib.LoanTypeEnum public immutable LOAN_TYPE;
    LoanAssetLib.InterestRateTypeEnum public immutable INTEREST_RATE_TYPE;
    LoanAssetLib.LoanStatusEnum public currentLoanStatus;

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
            msg.sender == ISSUER,
            "Only the lender can perform this action."
        );
        _;
    }

    // only enable borrower
    modifier onlyActiveBorrower() {
        require(
            BORROWERS_STATUS[msg.sender] ==
                LoanAssetLib.BorrowerStatusEnum.ACTIVE,
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
        require(
            _loanAnag.name != "",
            "Name must be different from empty string."
        );

        require(
            _loanAnag.issuanceCountry != "",
            "Issuance country must be different from empty string."
        );

        require(
            _loanAnag.currency != "",
            "Currency must be different from empty string."
        );

        require(
            _loanAnag.startDate > block.timestamp,
            "Start date must be in the future."
        );

        require(
            _loanAnag.maturityDate > block.timestamp,
            "Maturity date must be in the future."
        );

        require(
            _loanInfo.totalAmount > 0,
            "Total amount must be greater than zero."
        );
        require(
            _loanInfo.borrowers.length == _loanInfo.borrowersShares.length,
            "Mismatch in borrowers and shares."
        );
        require(
            _loanAnag.startDate < _loanAnag.maturityDate,
            "Start date must be before maturity date."
        );

        ISSUER = msg.sender;

        NAME = _loanAnag.name;
        ISSUANCE_COUNTRY = _loanAnag.issuanceCountry;
        CURRENCY = _loanAnag.currency;
        TOTAL_AMOUNT = _loanInfo.totalAmount;
        START_DATE = _loanAnag.startDate;
        MATURITY_DATE = _loanAnag.maturityDate;
        LOAN_TYPE = _loanAnag.loanType;
        INTEREST_RATE_TYPE = _loanAnag.interestRateType;
        TOTAL_REPAYMENT_NUMBER = _loanInfo.repaymentsDates.length;

        interestRate = _loanInfo.interestRate;

        // set repayment dates
        for (
            uint256 repaymentIndex = 0;
            repaymentIndex < _loanInfo.repaymentsDates.length;

        ) {
            REPAYMENTS_DATES[repaymentIndex] = _loanInfo.repaymentsDates[
                repaymentIndex
            ];
            unchecked {
                repaymentIndex++;
            }
        }

        // set lenders
        uint256 lendersLength = _loanInfo.lenders.length; // gas optimization
        for (uint256 lenderIndex = 0; lenderIndex < lendersLength; ) {
            address lender = _loanInfo.lenders[lenderIndex];
            uint256 share = _loanInfo.lendersShares[lenderIndex];

            require(share > 0, "Lender share must be greater than zero.");

            // set lender status
            LENDERS.push(lender);
            LENDERS_SHARES[lender] = share;
            LENDERS_STATUS[lender] = LoanAssetLib.LenderStatusEnum.ACTIVE;

            unchecked {
                lenderIndex++;
            }
        }

        uint256 repaymentsLength = _loanInfo.repaymentsDates.length; // gas optimization

        // set percentage of shares for each borrower and repayment
        uint256 borrowersLength = _loanInfo.borrowers.length; // gas optimization
        for (uint256 borrowerIndex = 0; borrowerIndex < borrowersLength; ) {
            address borrower = _loanInfo.borrowers[borrowerIndex];
            uint256 share = _loanInfo.borrowersShares[borrowerIndex];

            require(share > 0, "Borrower share must be greater than zero.");

            // set borrower status
            BORROWERS.push(borrower);
            BORROWERS_SHARES[borrower] = share;
            BORROWERS_STATUS[borrower] = LoanAssetLib.BorrowerStatusEnum.ACTIVE;

            // set outstanding principal amount and repayment number left to pay
            borrowersOutstandingPrincipals[borrower] = LoanAssetLib
                .OutstandingInfo({
                    outstandingPrincipalAmount: (TOTAL_AMOUNT * share) / 100,
                    repaymentNumberLeftToPay: repaymentsLength
                });

            // if IR fixed, calculate repayment amount for each borrower and all next repayments
            if (
                _loanAnag.interestRateType ==
                LoanAssetLib.InterestRateTypeEnum.FIXED
            ) {
                for (
                    uint256 repaymentIndex = 0;
                    repaymentIndex < repaymentsLength;

                ) {
                    // create repayments
                    borrowersRepayments[_loanInfo.borrowers[borrowerIndex]][
                        repaymentIndex
                    ] = _createNextRepayment(
                        _loanInfo.borrowers[borrowerIndex],
                        _loanInfo.repaymentsDates[repaymentIndex]
                    );

                    unchecked {
                        repaymentIndex++;
                    }
                }
            } else if (
                _loanAnag.interestRateType ==
                LoanAssetLib.InterestRateTypeEnum.FLOATING
            ) {
                // if floating and the IR must be inserted for each repayment manually, so set only the first one
                borrowersRepayments[_loanInfo.borrowers[borrowerIndex]][
                    0
                ] = _createNextRepayment(
                    _loanInfo.borrowers[borrowerIndex],
                    _loanInfo.repaymentsDates[0]
                );
            } else {
                revert("Invalid interest rate type.");
            }

            unchecked {
                borrowerIndex++;
            }
        }

        currentLoanStatus = LoanAssetLib.LoanStatusEnum.PRELIMINARY;

        emit LoanIssuedEvent(NAME, ISSUER, TOTAL_AMOUNT);
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

    // create next repayment
    function _createNextRepayment(
        address _borrower,
        uint256 _paymentDate
    ) private view returns (LoanAssetLib.RepaymentInfo memory repaymentInfo) {
        return
            LoanAssetLib.RepaymentInfo({
                amount: _calculateNextRepaymentAmountByBorrower(_borrower),
                repaymentDate: _paymentDate,
                repaymentStatus: LoanAssetLib.RepaymentStatusEnum.UNPAID
            });
    }

    // calculate amount to pay based on outstanding
    function _calculateNextRepaymentAmountByBorrower(
        address borrower
    ) private view returns (uint256) {
        LoanAssetLib.OutstandingInfo
            memory borrowerOutstandingInfo = borrowersOutstandingPrincipals[
                borrower
            ];

        uint256 interestMatured = (borrowerOutstandingInfo
            .outstandingPrincipalAmount * interestRate) / 100; /*interest*/
        if (LoanAssetLib.LoanTypeEnum.AMORTIZED == LOAN_TYPE) {
            uint256 repaymentsCountLeftToPay = TOTAL_REPAYMENT_NUMBER -
                borrowerOutstandingInfo.repaymentNumberLeftToPay;
            return
                (borrowerOutstandingInfo.outstandingPrincipalAmount *
                    repaymentsCountLeftToPay) /* principal */ +
                interestMatured; /*interest*/
        } else if (LoanAssetLib.LoanTypeEnum.BULLET == LOAN_TYPE) {
            return interestMatured; /*interest*/
        } else {
            revert("Invalid loan type.");
        }
    }

    function calculateNextRepaymentAmount() public view returns (uint256) {
        return _calculateNextRepaymentAmountByBorrower(msg.sender);
    }

    // Over the start date, the loan can be started
    function setLoanStart() external onlyOwner {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatusEnum.PRELIMINARY,
            "Loan is not in preliminary state!"
        );
        currentLoanStatus = LoanAssetLib.LoanStatusEnum.LIVE;

        emit LoanStartedEvent();
    }

    // set interest rate
    function updateInterestRateAndRepayments(
        uint256 _interestRate
    ) external onlyOwner {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatusEnum.PRELIMINARY,
            "Loan is not in preliminary state!"
        );

        require(_interestRate > 0, "Interest rate must be greater than zero.");

        require(
            INTEREST_RATE_TYPE == LoanAssetLib.InterestRateTypeEnum.FLOATING,
            "Interest rate type must be floating."
        );

        interestRate = _interestRate;

        // set next repayment amount for each borrower
        uint256 borrowersLength = BORROWERS.length; // gas optimization
        for (uint256 borrowersIndex = 0; borrowersIndex < borrowersLength; ) {
            address borrower = BORROWERS[borrowersIndex];

            LoanAssetLib.OutstandingInfo
                memory borrowerOutstandingInfo = borrowersOutstandingPrincipals[
                    borrower
                ];

            uint256 nextRepaymentIndex = TOTAL_REPAYMENT_NUMBER -
                borrowerOutstandingInfo.repaymentNumberLeftToPay +
                1; // gas optimization

            // if someone has already paid all the repayments, skip
            if (nextRepaymentIndex >= TOTAL_REPAYMENT_NUMBER) {
                unchecked {
                    borrowersIndex++;
                }
                continue;
            }

            borrowersRepayments[BORROWERS[borrowersIndex]][
                nextRepaymentIndex
            ] = LoanAssetLib.RepaymentInfo({
                amount: _calculateNextRepaymentAmountByBorrower(
                    BORROWERS[borrowersIndex]
                ),
                repaymentDate: REPAYMENTS_DATES[nextRepaymentIndex],
                repaymentStatus: LoanAssetLib.RepaymentStatusEnum.UNPAID
            });

            unchecked {
                borrowersIndex++;
            }
        }

        emit UpdateInterestPaymentAndRepaymentsEvent(_interestRate);
    }

    // Borrower request to pay a repayment
    function payRepayment(
        uint256 repaymentNumber
    ) external payable nonReentrant onlyActiveBorrower {
        // check loan status
        require(
            currentLoanStatus == LoanAssetLib.LoanStatusEnum.LIVE,
            "Loan is not live."
        );

        LoanAssetLib.OutstandingInfo
            storage borrowerOutstandingInfo = borrowersOutstandingPrincipals[
                msg.sender
            ];

        require(
            repaymentNumber < TOTAL_REPAYMENT_NUMBER,
            "Invalid repayment number."
        );

        LoanAssetLib.RepaymentInfo storage repaymentInfo = borrowersRepayments[
            msg.sender
        ][repaymentNumber];

        // check on repayment status
        require(
            repaymentInfo.repaymentStatus ==
                LoanAssetLib.RepaymentStatusEnum.UNPAID,
            "Repayment has already been paid."
        );
        require(
            repaymentInfo.repaymentDate <= block.timestamp,
            "Repayment date has not been reached yet."
        );

        // check on amount
        uint256 repaymentAmount = _calculateNextRepaymentAmountByBorrower(
            msg.sender
        );
        require(
            repaymentAmount != 0,
            "Repayment must be defined before being paid."
        );
        require(
            msg.value == repaymentAmount,
            "Incorrect repayment amount sent."
        );

        // update outstanding info
        if (LoanAssetLib.LoanTypeEnum.AMORTIZED == LOAN_TYPE) {
            borrowerOutstandingInfo
                .outstandingPrincipalAmount -= repaymentAmount;
        }
        borrowerOutstandingInfo.repaymentNumberLeftToPay--;

        // update repayment status
        repaymentInfo.repaymentStatus = LoanAssetLib.RepaymentStatusEnum.PAID;

        // payment from msg.sender to smart contract on the payable function
        // TODO ERC20 transfer

        emit RepaymentPaidEvent(msg.sender, repaymentAmount, repaymentNumber);
    }

    // Pay principal
    function payPrincipal() external payable nonReentrant onlyActiveBorrower {
        // check loan status
        require(
            currentLoanStatus == LoanAssetLib.LoanStatusEnum.MATURED,
            "Loan is not matured."
        );

        uint principalAmount = _calculateNextRepaymentAmountByBorrower(
            msg.sender
        );
        require(
            principalAmount != 0,
            "No outstanding principal amount to pay."
        );

        LoanAssetLib.OutstandingInfo
            storage borrowerOutstandingInfo = borrowersOutstandingPrincipals[
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

        // update outstanding principal amount and repayment number left to pay
        borrowerOutstandingInfo.outstandingPrincipalAmount = 0;
        borrowerOutstandingInfo.repaymentNumberLeftToPay = 0;

        // update borrower status
        BORROWERS_STATUS[msg.sender] = LoanAssetLib.BorrowerStatusEnum.REPAID;

        // payment from msg.sender to smart contract on the payable function
        // TODO ERC20 transfer

        emit LoanRepaidEvent(msg.sender, msg.value);
    }

    function setDefault(address borrower) external onlyOwner {
        require(
            BORROWERS_STATUS[borrower] ==
                LoanAssetLib.BorrowerStatusEnum.ACTIVE,
            "Borrower is not active."
        );

        BORROWERS_STATUS[borrower] = LoanAssetLib.BorrowerStatusEnum.DEFAULTED;
    }

    function enableAnticipatePayment(address borrower) external onlyOwner {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatusEnum.LIVE,
            "Loan must be live to anticipate payment."
        );

        require(
            BORROWERS_STATUS[borrower] ==
                LoanAssetLib.BorrowerStatusEnum.ACTIVE,
            "Borrower is not active to anticipate payment."
        );

        // check borrower outstanding
        LoanAssetLib.OutstandingInfo
            memory borrowerOutstandingInfo = borrowersOutstandingPrincipals[
                borrower
            ];

        require(
            borrowerOutstandingInfo.outstandingPrincipalAmount != 0 &&
                borrowerOutstandingInfo.repaymentNumberLeftToPay != 0,
            "No outstanding principal amount or repayment left to pay."
        );

        BORROWERS_STATUS[msg.sender] = LoanAssetLib
            .BorrowerStatusEnum
            .ANTICIPATED;
    }

    function disableAnticipatePayment(address borrower) external onlyOwner {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatusEnum.LIVE,
            "Loan must be live to anticipate payment."
        );

        require(
            BORROWERS_STATUS[borrower] ==
                LoanAssetLib.BorrowerStatusEnum.ANTICIPATED,
            "Borrower is not enabled to anticipate payment."
        );

        BORROWERS_STATUS[msg.sender] = LoanAssetLib.BorrowerStatusEnum.ACTIVE;
    }

    function anticipatePayment() external payable nonReentrant {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatusEnum.LIVE,
            "Loan must be live to anticipate payment."
        );

        require(
            BORROWERS_STATUS[msg.sender] ==
                LoanAssetLib.BorrowerStatusEnum.ANTICIPATED,
            "Borrower is not enabled to anticipate payment."
        );

        address borrower = msg.sender;

        LoanAssetLib.OutstandingInfo
            storage borrowerOutstandingInfo = borrowersOutstandingPrincipals[
                borrower
            ];

        uint256 paymentAmount = (borrowerOutstandingInfo
            .outstandingPrincipalAmount * interestRate) / 100;

        require(
            msg.value >= paymentAmount,
            "Insufficient funds to anticipate payment."
        );

        // update outstanding principal amount and repayment number left to pay
        borrowerOutstandingInfo.outstandingPrincipalAmount = 0;
        borrowerOutstandingInfo.repaymentNumberLeftToPay = 0;

        // update borrower status
        BORROWERS_STATUS[borrower] = LoanAssetLib.BorrowerStatusEnum.REPAID;

        // payment from msg.sender to smart contract on the payable function
        // TODO ERC20 transfer

        emit LoanRepaidEvent(borrower, paymentAmount);
    }

    // set loan matured request
    function setLoanMatured() external onlyOwner {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatusEnum.LIVE,
            "Loan must be live to close it."
        );
        require(block.timestamp >= MATURITY_DATE, "Loan has not matured yet.");
        currentLoanStatus = LoanAssetLib.LoanStatusEnum.MATURED;

        emit LoanMaturedEvent();
    }

    // close loan request
    function setLoanClosed() external onlyOwner {
        require(
            currentLoanStatus == LoanAssetLib.LoanStatusEnum.MATURED,
            "Loan must be matured before closing."
        );

        // check each borrower paid outstanding principal amount (so implicit repayments)
        uint256 borrowersLength = BORROWERS.length; // gas optimization
        for (uint256 borrowersIndex = 0; borrowersIndex < borrowersLength; ) {
            // BUT if some borrower is set to DEFAULTED, skip
            if (
                BORROWERS_STATUS[BORROWERS[borrowersIndex]] ==
                LoanAssetLib.BorrowerStatusEnum.DEFAULTED
            ) {
                unchecked {
                    borrowersIndex++;
                }
                continue;
            }

            // if some borrower has not paid all the repayments, revert
            require(
                borrowersOutstandingPrincipals[BORROWERS[borrowersIndex]]
                    .repaymentNumberLeftToPay == 0,
                "All borrowers must pay all repayments before closing."
            );
            unchecked {
                borrowersIndex++;
            }
        }

        currentLoanStatus = LoanAssetLib.LoanStatusEnum.CLOSED;
    }

    function withdrawFunds() external nonReentrant onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}
