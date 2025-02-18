// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./LoanAssetLib.sol";

interface ILoanAsset {
    // #################################### //
    // ############## ERRORS ############## //
    // #################################### //
    error InvalidACLOwnerError(string err, address caller);
    error InvalidACLBorrowerError(string err, address caller);
    error InvalidACLLenderError(string err, address lender);
    error ReentrancyGuardError(string err);
    error PausedError(string err);
    error InvalidEmptyValueError(string err);
    error InvalidValueError(string err);
    error InvalidMathRestrictionStartMaturityDateError(
        string err,
        uint256 startDate,
        uint256 maturityDate
    );
    error InvalidZeroValueError(string err);
    error InvalidZeroLenghtError(string err);
    error InvalidLengthSharesForBorrowerError(
        string err,
        uint256 shares,
        uint256 borrowers
    );

    error InvalidLengthSharesForLenderError(
        string err,
        uint256 shares,
        uint256 lenders
    );
    error InvalidLengthInterestRateForBorrowerError(
        string err,
        uint256 interestRate,
        uint256 borrowers
    );
    error InvalidMathRestrictionSharesLender(
        string err,
        uint256 shares,
        uint256 totalShares
    );
    error InvalidMathRestrictionSharesBorrower(
        string err,
        uint256 shares,
        uint256 totalShares
    );
    error InvalidValueInterestRateType(
        string err,
        LoanAssetLib.InterestRateTypeEnum currentInterestRateType,
        LoanAssetLib.InterestRateTypeEnum expectedInterestRateType
    );
    error InvalidValueLoanType(string err, LoanAssetLib.LoanTypeEnum loanType);
    error InvalidValueLoanStatus(
        string err,
        LoanAssetLib.LoanStatusEnum currentLoanStatus,
        LoanAssetLib.LoanStatusEnum expectedLoanStatus
    );
    error InvalidLenghtInterestRateForBorrower(
        string err,
        uint256 interestRate,
        uint256 borrowers
    );
    error InvalidValueRepaymentIndex(
        string err,
        uint256 expectedRepaymentIndex,
        uint256 repaymentIndex
    );
    error InvalidValueBorrowerStatus(
        string err,
        LoanAssetLib.BorrowerStatusEnum currentBorrowerStatus,
        LoanAssetLib.BorrowerStatusEnum expectedBorrowerStatus
    );

    error InvalidValueLenderStatus(
        string err,
        LoanAssetLib.LenderStatusEnum currentLenderStatus,
        LoanAssetLib.LenderStatusEnum expectedLenderStatus
    );
    error InsufficientFunds(string err);
    error InvalidStatusRepayFromAllBorrowers(
        string err,
        address borrower,
        LoanAssetLib.RepaymentStatusEnum currentBorrowerStatus,
        LoanAssetLib.RepaymentStatusEnum expectedBorrowerStatus
    );

    error InvalidAmountToFund(string err, uint256 amountToFund);

    error InvalidAmountRepayFromAllBorrowers(
        string err,
        address borrower,
        uint256 currentBorrowerStatus,
        uint256 expectedBorrowerStatus
    );

    error UnknownValueInterestRateType(
        string err,
        LoanAssetLib.InterestRateTypeEnum interestRateType
    );

    // #################################### //
    // ############### EVENT ############## //
    // #################################### //

    event FundsDepositedEvent(address indexed sender, uint256 amount);

    event LoanIssuedEvent(
        bytes32 name,
        address indexed lender,
        uint256 totalAmount
    );

    event LoanFundedEvent(
        address indexed lender,
        uint256 amount,
        uint256 totalAmount
    );

    event LoanStartedEvent();

    event RepaymentPaidEvent(
        address indexed borrower,
        uint256 repaymentAmount,
        uint256 repaymentNumber
    );

    event UpdateInterestRateAndRepaymentsEvent(uint256[] interestRates);

    event LoanMaturedEvent();

    event LoanRepaidEvent(address indexed borrower, uint256 repaymentAmount);

    // ##################################### //
    // ############### VIEW ################ //
    // ##################################### //

    function depositFunds() external payable;
    function setLoanStart() external;
    function payPrincipal() external payable;
    function setLoanMatured() external;
    function setLoanClosed() external;
    function withdrawFunds() external;
}
