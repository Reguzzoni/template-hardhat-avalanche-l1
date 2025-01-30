// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title ISecurityAsset
 * @dev This interface defines the functions and properties for a security asset.
 *
 * Security assets can represent various financial instruments such as Security assets and Bonds.
 * They can have different statuses including Preliminary, Live, Matured, and Closed.
 * Security assets are ERC20 tokens and can be minted, burned and transferred.
 */
interface ISecurityAsset is IAccessControl, IERC20, IERC20Metadata {
    // Enums

    /**
     * @dev Enumeration for the type of Security Asset.
     * CustomSecurityAsset: Represents a Security asset financial instrument.
     * Bond: Represents a Bond financial instrument.
     */
    enum Type {
        CustomSecurityAsset,
        Bond
    }

    /**
     * @dev Enumeration for the status of the Security Asset.
     * Preliminary: The initial state where security parameters can be set.
     * Live: The asset is active and can be traded.
     * Matured: The asset has reached maturity.
     * Closed: The asset is closed and no longer tradable.
     */
    enum Status {
        Preliminary,
        Live,
        Matured,
        Closed
    }

    // Events

    /**
     * @dev Emitted when new tokens are minted.
     * @param to The address to which tokens are minted.
     * @param amount The amount of tokens minted.
     */
    event Mint(address indexed to, uint256 amount);

    /**
     * @dev Emitted when new tokens are minted, using the batched version.
     * @param accounts Array of accounts that will receive tokens.
     * @param amounts Array of amounts that will be minted for each account.
     */
    event BatchMint(address[] accounts, uint256[] amounts);

    /**
     * @dev Emitted when tokens are burned and new tokens are minted in a transfer.
     * @param from The address from which tokens are burned.
     * @param to The address to which new tokens are minted.
     * @param value The amount of tokens burned.
     */
    event BurnAndMint(address from, address to, uint256 value);

    event Initialized(
        Type securityType,
        bool isLive_,
        string name_,
        string symbol_,
        string isin_,
        string issuanceCountry_,
        string currency_,
        string maturity_,
        uint64 minimumDenomination_,
        string addInfoUri_,
        string checksum_,
        uint256 cap_,
        address restrictionsSmartContract_,
        address issuer_
    );

    /**
     * @dev Emitted when a property of the Security Asset is changed.
     * @param propertyName The name of the property that was changed.
     * @param valueType The data type of the property.
     * @param oldValue The old value of the property.
     * @param newValue The new value of the property.
     */
    event PropertyChanged(
        string propertyName,
        string valueType,
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when a an address is added or removed from/to escrow list
     * @param _address The address that was added or removed
     * @param change Property to show if the address was added or removed
     */
    event EscrowListChanged(address _address, string change);
    /**
     * @dev Emitted when a property of the Security Asset is changed (string version).
     * @param propertyName The name of the property that was changed.
     * @param valueType The data type of the property (string).
     * @param oldValue The old value of the property.
     * @param newValue The new value of the property.
     */
    event PropertyChanged(
        string propertyName,
        string valueType,
        string oldValue,
        string newValue
    );

    /**
     * @dev Emitted when a property of the Security Asset is changed (address version).
     * @param propertyName The name of the property that was changed.
     * @param valueType The data type of the property (address).
     * @param oldValue The old value of the property.
     * @param newValue The new value of the property.
     */
    event PropertyChanged(
        string propertyName,
        string valueType,
        address oldValue,
        address newValue
    );

    /**
     * @dev Emitted when the status of the Security Asset is changed.
     * @param previous The previous status.
     * @param actual The new status.
     */
    event ChangeStatus(Status previous, Status actual);

    // Business functions

    /**
     * @dev Mint new tokens and assign them to an account.
     * @param account The address to which tokens are minted.
     * @param amount The amount of tokens to mint.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Burn tokens from one address and mint new tokens to another address in a single transaction.
     * @param from The address from which tokens are burned.
     * @param to The address to which new tokens are minted.
     * @param amount The amount of tokens to burn and mint.
     */
    function burnAndMint(address from, address to, uint256 amount) external;

    /**
     * @dev Batch mint tokens for multiple accounts.
     */
    function batchMint(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev Add an issuer with the necessary roles.
     * @param issuer_ The address of the new issuer.
     */
    function addIssuer(address issuer_) external;

    /**
     * @dev Add an escrow contract that can transfer tokens after maturity
     * @param escrow_ The address of the new escrow.
     */
    function addEscrow(address escrow_) external;

    /**
     * @dev Remove an escrow contract that can transfer tokens after maturity
     * @param escrow_ The address of the escrow to be removed.
     */
    function removeEscrow(address escrow_) external;

    // Getters

    /**
     * @dev Get the type of the Security Asset.
     * @return The type of the Security Asset (CustomSecurityAsset or Bond).
     */
    function securityType() external view returns (Type);

    /**
     * @dev Get the ISIN (International Securities Identification Number) of the Security Asset.
     * @return The ISIN of the Security Asset.
     */
    function isin() external view returns (string memory);

    /**
     * @dev Get the currency in which the Security Asset is denominated.
     * @return The currency of the Security Asset.
     */
    function currency() external view returns (string memory);

    /**
     * @dev Get the maturity date of the Security Asset.
     * @return The maturity date in string format.
     */
    function maturity() external view returns (string memory);

    /**
     * @dev Get the minimum denomination for transferring tokens.
     * @return The minimum denomination amount.
     */
    function minimumDenomination() external view returns (uint64);

    /**
     * @dev Get the additional information URI associated with the Security Asset.
     * @return The URI string.
     */
    function addInfoUri() external view returns (string memory);

    /**
     * @dev Get the checksum of the Security Asset.
     * @return The checksum string.
     */
    function checksum() external view returns (string memory);

    /**
     * @dev Get the address of the whitelist contract associated with the Security Asset.
     * @return The address of the whitelist contract.
     */
    function restrictionsSmartContract() external view returns (address);

    /**
     * @dev Get the current status of the Security Asset.
     * @return The current status (Preliminary, Live, Matured, Closed).
     */
    function status() external view returns (Status);

    /**
     * @dev Get the issuance country of the Security Asset.
     * @return The issuance country as a string.
     */
    function issuanceCountry() external view returns (string memory);

    /**
     * @dev Get the address of the issuer of the Security Asset.
     * @return The address of the issuer.
     */
    function issuer() external view returns (address);

    // Setters

    /**
     * @dev Set the name of the Security Asset.
     * @param name The new name.
     */
    function setName(string calldata name) external;

    /**
     * @dev Set the symbol of the Security Asset.
     * @param symbol The new symbol.
     */
    function setSymbol(string calldata symbol) external;

    /**
     * @dev Set a new issuer for the security asset.
     * @param issuer The address of the new issuer.
     */
    function setIssuer(address issuer) external;

    /**
     * @dev Set the ISIN (International Securities Identification Number) of the Security Asset.
     * @param isin The new ISIN.
     */
    function setISIN(string calldata isin) external;

    /**
     * @dev Set the checksum of the Security Asset.
     * @param value The new checksum.
     */
    function setChecksum(string calldata value) external;

    /**
     * @dev Set the type of the Security Asset (CustomSecurityAsset or Bond).
     * @param securityType_ The new type.
     */
    function setSecurityType(Type securityType_) external;

    /**
     * @dev Set the maturity date of the Security Asset.
     * @param date The new maturity date in string format.
     */
    function setMaturity(string calldata date) external;

    /**
     * @dev Set the minimum denomination for transferring tokens.
     * @param amount The new minimum denomination amount.
     */
    function setMinimumDenomination(uint64 amount) external;

    /**
     * @dev Set the currency in which the Security Asset is denominated.
     * @param currency_ The new currency.
     */
    function setCurrency(string calldata currency_) external;

    /**
     * @dev Set the additional information URI associated with the Security Asset.
     * @param info The new URI string.
     */
    function setAddInfoUri(string calldata info) external;

    /**
     * @dev Set the issuance country of the Security Asset.
     * @param country The new issuance country as a string.
     */
    function setIssuanceCountry(string calldata country) external;

    // Change status

    /**
     * @dev Change the status of the Security Asset to Live.
     */
    function setLive() external;

    /**
     * @dev Change the status of the Security Asset to Matured.
     */
    function setMatured() external;

    /**
     * @dev Change the status of the Security Asset to Closed.
     */
    function setClosed() external;

    // Pause

    /**
     * @dev Pause the Security Asset.
     */
    function pause() external;

    /**
     * @dev Unpause the Security Asset.
     */
    function unpause() external;
}
