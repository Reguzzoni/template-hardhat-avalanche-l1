// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILoanAsset {
    // #################################### //
    // ############### EVENT ############## //
    // #################################### //

    event LoanIssuedEvent(
        bytes32 name,
        address indexed lender,
        uint256 totalAmount
    );

    event UpdateInterestPaymentAndRepaymentsEvent(uint256 interestRate);

    event LoanStartedEvent();

    event RepaymentPaidEvent(
        address indexed borrower,
        uint256 repaymentAmount,
        uint256 repaymentNumber
    );

    event LoanMaturedEvent();

    event LoanRepaidEvent(address indexed borrower, uint256 repaymentAmount);
}
