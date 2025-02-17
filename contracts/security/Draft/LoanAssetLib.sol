// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
library LoanAssetLib {
    enum LoanType {
        BULLET,
        AMORTIZED
    }

    enum LoanStatus {
        PRELIMINARY,
        LIVE,
        MATURED,
        CLOSED
    }

    enum InterestRateType {
        FIXED,
        FLOATING
    }

    enum CouponStatus {
        UNPAID,
        PAID
    }

    enum BorrowerStatus {
        ACTIVE,
        REPAID,
        DEFAULTED,
        ANTICIPATED
    }

    struct LoanAnag {
        bytes32 name;
        bytes32 issuanceCountry;
        bytes32 currency;
        LoanType loanType;
        InterestRateType interestRateType;
        uint256 startDate;
        uint256 maturityDate;
    }

    struct LoanInfo {
        uint256 totalAmount;
        uint256 interestRate;
        uint256[] couponPaymentDates;
        address[] borrowers;
        uint256[] borrowerShares;
    }

    struct CouponInfo {
        uint256 amount;
        uint256 paymentDate;
        CouponStatus couponStatus;
    }

    struct OutstandingInfo {
        uint256 outstandingPrincipalAmount;
        uint256 couponNumberLeftToPay;
    }

    event LoanIssued(bytes32 name, address indexed lender, uint256 totalAmount);

    event UpdateInterestRateAndCoupon(uint256 interestRate);

    event LoanStarted();

    event CouponPaid(
        address indexed borrower,
        uint256 couponAmount,
        uint256 couponNumber
    );

    event LoanMatured();

    event LoanRepaid(address indexed borrower, uint256 repaymentAmount);
}
