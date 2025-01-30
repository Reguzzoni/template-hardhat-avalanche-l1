// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./SecurityAsset.sol";

/**
 * @title CustomSecurityAsset
 * @dev This contract represents a security asset, which is a specific type of security asset.
 *
 * Security assets inherit all the properties and functionalities from the SecurityAsset contract.
 * They can have different statuses such as Preliminary, Live, Matured, and Closed, and are ERC20 tokens
 * that can be minted, burned, and transferred. This contract also integrates access control and pausing mechanisms.
 */
contract CustomSecurityAsset is SecurityAsset {
    /**
     * @dev Constructor to initialize the security asset contract.
     * It delegates the initialization to the SecurityAsset contract's constructor by passing the required parameters.
     * @param isLive_ A flag indicating if the Security asset is live.
     * @param name_ The name of the Security asset.
     * @param symbol_ The symbol of the Security asset.
     * @param isin_ The ISIN (International Securities Identification Number) of the Security asset.
     * @param issuanceCountry_ The country of issuance for the Security asset.
     * @param currency_ The currency of the Security asset.
     * @param maturity_ The maturity date of the Security asset.
     * @param minimumDenomination_ The minimum denomination of the Security asset.
     * @param addInfoUri_ The URI providing additional information about the Security asset.
     * @param checksum_ The checksum associated with the Security asset.
     * @param cap_ The cap or maximum supply of the Security asset.
     * @param restrictionsSmartContract_ The address of the Restrictions smart contract for access control.
     * @param issuer_ The address of the issuer of the Security asset.
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
            Type.CustomSecurityAsset,
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
