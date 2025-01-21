// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

library HLClib {
    enum StatusHLC {
        Inizialized,
        Executed,
        Cancelled
    }

    enum StatusAssetLeg {
        Empty,
        Deposited
    }

    enum StatusPaymentLeg {
        Empty,
        Deposited
    }

    //-------------------------------------//
    //--------------- EVENTS --------------//
    //-------------------------------------//

    event Initialized(
        address indexed _seller,
        address indexed _buyer,
        string _price,
        uint _assetTokenAmount,
        uint _paymentTokenAmount,
        bytes _tipsId,
        address _assetTokenAddress,
        address _paymentTokenAddress
    );

    event AssetTokenWithdrawn(
        address indexed _from,
        address indexed _assetTokenAddress,
        uint _amount
    );

    event PaymentTokenWithdrawn(
        address indexed _from,
        address indexed _paymentTokenAddress,
        uint _amount
    );

    event AssetTokenDeposited(
        address indexed _from,
        address indexed _assetTokenAddress,
        uint _amount
    );
    event PaymentTokenDeposited(
        address indexed _from,
        address indexed _paymentTokenAddress,
        uint _amount
    );

    event Execution(address indexed _from, address indexed _to);

    event CooperativeExecution(address indexed _from, address indexed _to);
    event ForcedExecution(address indexed _from, address indexed _to);
    event CooperativeCancellation(address indexed _from, address indexed _to);
    event ForcedCancellation(address indexed _from, address indexed _to);
}
