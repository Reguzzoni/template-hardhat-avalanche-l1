// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
library LoanAssetLib {
    // ##################################### //
    // ############### ENUM ################ //
    // ##################################### //
    enum LoanTypeEnum {
        BULLET,
        AMORTIZED
    }

    enum InterestRateTypeEnum {
        FIXED,
        FLOATING
    }

    enum LoanStatusEnum {
        PRELIMINARY,
        LIVE,
        MATURED,
        CLOSED
    }

    enum RepaymentStatusEnum {
        UNPAID,
        PAID
    }

    enum BorrowerStatusEnum {
        ACTIVE,
        REPAID,
        DEFAULTED,
        ANTICIPATED
    }

    enum LenderStatusEnum {
        ACTIVE,
        INACTIVE
    }

    // ##################################### //
    // ############### STRUCT ############## //
    // ##################################### //

    struct LoanAnag {
        bytes32 name;
        bytes32 issuanceCountry;
        bytes32 currency;
        LoanTypeEnum loanType;
        InterestRateTypeEnum interestRateType;
        uint256 startDate;
        uint256 maturityDate;
    }

    struct LoanInfo {
        uint256 totalAmount;
        uint256 interestRate;
        uint256[] repaymentsDates;
        address[] lenders;
        uint256[] lendersShares;
        address[] borrowers;
        uint256[] borrowersShares;
    }

    struct RepaymentInfo {
        uint256 amount;
        uint256 repaymentDate;
        RepaymentStatusEnum repaymentStatus;
    }

    struct OutstandingInfo {
        uint256 outstandingPrincipalAmount;
        uint256 repaymentNumberLeftToPay;
    }
}
