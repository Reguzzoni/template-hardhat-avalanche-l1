// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./SecurityAsset.sol";

/**
 * @title CommercialPaper
 * @dev This contract represents a commercial paper, which is a specific type of security asset.
 *
 * Commercial papers inherit all the properties and functionalities from the SecurityAsset contract.
 * They can have different statuses such as Preliminary, Live, Matured, and Closed, and are ERC20 tokens
 * that can be minted, burned, and transferred. This contract also integrates access control and pausing mechanisms.
 */
contract CommercialPaper is SecurityAsset {
    /**
     * @dev Constructor to initialize the commercial paper contract.
     * It delegates the initialization to the SecurityAsset contract's constructor by passing the required parameters.
     * @param isLive_ A flag indicating if the Commercial Paper is live.
     * @param name_ The name of the Commercial Paper.
     * @param symbol_ The symbol of the Commercial Paper.
     * @param isin_ The ISIN (International Securities Identification Number) of the Commercial Paper.
     * @param issuanceCountry_ The country of issuance for the Commercial Paper.
     * @param currency_ The currency of the Commercial Paper.
     * @param maturity_ The maturity date of the Commercial Paper.
     * @param minimumDenomination_ The minimum denomination of the Commercial Paper.
     * @param addInfoUri_ The URI providing additional information about the Commercial Paper.
     * @param checksum_ The checksum associated with the Commercial Paper.
     * @param cap_ The cap or maximum supply of the Commercial Paper.
     * @param restrictionsSmartContract_ The address of the Restrictions smart contract for access control.
     * @param issuer_ The address of the issuer of the Commercial Paper.
     */
    constructor(
        bool isLive_,
        string memory name_,
        string memory symbol_,
        string memory isin_,
        string memory issuanceCountry_,
        string memory currency_,
        string memory maturity_,
        uint64 minimumDenomination_,
        string memory addInfoUri_,
        string memory checksum_,
        uint256 cap_,
        address restrictionsSmartContract_,
        address issuer_
    )
        SecurityAsset(
            Type.CommercialPaper,
            isLive_,
            name_,
            symbol_,
            isin_,
            issuanceCountry_,
            currency_,
            maturity_,
            minimumDenomination_,
            addInfoUri_,
            checksum_,
            cap_,
            restrictionsSmartContract_,
            issuer_
        )
    {}
}
