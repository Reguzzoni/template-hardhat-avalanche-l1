// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

library HLClib {
    enum Status {
        Inizialized,
        Executed,
        Cancelled
    }

    //-------------------------------------//
    //--------------- EVENTS --------------//
    //-------------------------------------//

    event Initialized(
        address indexed _seller,
        address indexed _buyer,
        string _price,
        uint _tokenAmount,
        bytes _tipsId,
        address _token_address
    );

    event CooperativeExecution(address indexed _from, address indexed _to);
    event ForcedExecution(address indexed _from, address indexed _to);
    event CooperativeCancellation(address indexed _from, address indexed _to);
    event ForcedCancellation(address indexed _from, address indexed _to);
}
