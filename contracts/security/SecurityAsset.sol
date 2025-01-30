// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./ISecurityAsset.sol";
import "./Restrictions.sol";

/**
 * @title SecurityAsset
 * @dev This abstract contract defines a security asset with various properties and functionalities.
 *
 * Security assets represent financial instruments and can have different statuses such as Preliminary, Live, Matured, and Closed.
 * They are ERC20 tokens that can be minted, burned, and transferred. This contract also integrates access control and pausing mechanisms.
 */
abstract contract SecurityAsset is
    ERC20Capped,
    Pausable,
    ISecurityAsset,
    AccessControl
{
    Status private _status = Status.Preliminary;
    uint8 private _decimals;
    Type private _securityType;
    bytes32 public constant ISSUER = keccak256("ISSUER");
    bytes32 public constant ISSUER_ADMIN = keccak256("ISSUER_ADMIN");
    uint64 private _minimumDenomination;
    address private _issuer;
    address private _restrictionsSmartContract;
    mapping(address => bool) public _redemptionEscrowContracts;

    string private _issuanceCountry;
    string private _currency;
    string private _maturity;
    string private _isin;
    string private _addInfoUri;
    string private _checksum;
    string private _name;
    string private _symbol;

    // Modifiers

    /**
     * @dev Modifier to restrict access to only issuers or admins.
     */
    modifier onlyIssuerOrRegistrar() virtual {
        require(
            hasRole(ISSUER, msg.sender) ||
                Restrictions(_restrictionsSmartContract).hasRole(
                    Restrictions(_restrictionsSmartContract).ADMIN(),
                    msg.sender
                ),
            "caller is not an issuer or a admin"
        );
        _;
    }

    /**
     * @dev Modifier to restrict access to only admins.
     */
    modifier onlyRegistrar() virtual {
        require(
            Restrictions(_restrictionsSmartContract).hasRole(
                Restrictions(_restrictionsSmartContract).ADMIN(),
                msg.sender
            ),
            "caller is not a admin"
        );
        _;
    }

    /**
     * @dev Modifier to check if the contract is not globally paused.
     */
    modifier whenNotGlobalPaused() virtual {
        require(
            !Restrictions(_restrictionsSmartContract).paused(),
            "Restrictions: All contracts are paused"
        );
        _;
    }

    /**
     * @dev Constructor to initialize the security asset contract.
     * It sets up the roles for issuers and admin administrators.
     * @param securityType_ The type of the security asset.
     * @param isLive_ A flag indicating if the security asset is live.
     * @param name_ The name of the security asset.
     * @param symbol_ The symbol of the security asset.
     * @param isin_ The ISIN (International Securities Identification Number) of the security asset.
     * @param issuanceCountry_ The country of issuance.
     * @param currency_ The currency of the security asset.
     * @param maturity_ The maturity date of the security asset.
     * @param minimumDenomination_ The minimum denomination of the security asset.
     * @param addInfoUri_ The URI providing additional information about the security asset.
     * @param checksum_ The checksum associated with the security asset.
     * @param cap_ The maximum supply for the security asset.
     * @param restrictionsSmartContract_ The address of the restrictions smart contract for access control.
     * @param issuer_ The address of the issuer of the security asset.
     * @notice Initialized is emitted to show all constructor parameters.
     */
    constructor(
        Type securityType_,
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
    ) ERC20Capped(cap_) ERC20(name_, symbol_) {
        _setRoleAdmin(ISSUER, ISSUER_ADMIN);

        _setupRole(ISSUER_ADMIN, msg.sender);

        _grantIssuerRoles(issuer_);

        emit Initialized(
            securityType_,
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
        );

        if (isLive_) _status = Status.Live;
        _name = name_;
        _symbol = symbol_;
        _isin = isin_;
        _securityType = securityType_;
        _issuanceCountry = issuanceCountry_;
        _currency = currency_;
        _maturity = maturity_;
        _minimumDenomination = minimumDenomination_;
        _addInfoUri = addInfoUri_;
        _checksum = checksum_;
        _restrictionsSmartContract = restrictionsSmartContract_;
        _issuer = issuer_;
        _decimals = 0;
    }

    // Business functions

    /**
     * @dev Mint tokens and assign them to an account.
     * @param account The address to receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(
        address account,
        uint256 amount
    )
        external
        override
        onlyIssuerOrRegistrar
        whenNotPaused
        whenNotGlobalPaused
    {
        require(
            Restrictions(_restrictionsSmartContract).isWhitelisted(account),
            "Account is not whitelisted"
        );
        require(
            _status == Status.Live,
            "minting is not allowed when the contract is not live"
        );

        _mint(account, amount);

        emit Mint(account, amount);
    }

    /**
     * @dev Burn tokens from one account and mint new tokens for another account in exchange.
     * @param from The address from which to burn tokens.
     * @param to The address to receive the new tokens.
     * @param amount The amount of tokens to burn.
     */
    function burnAndMint(
        address from,
        address to,
        uint256 amount
    ) external override onlyRegistrar {
        require(
            Restrictions(_restrictionsSmartContract).isWhitelisted(from),
            "Original holder is not whitelisted"
        );
        require(
            Restrictions(_restrictionsSmartContract).isWhitelisted(to),
            "recipient is not whitelisted"
        );
        require(
            amount % _minimumDenomination == 0,
            "amount must be multiple of minimumDenomination value"
        );
        _transfer(from, to, amount);

        emit BurnAndMint(from, to, amount);
    }

    /**
     * @dev Batch mint tokens for multiple accounts.
     * @param accounts_ Array of accounts that will receive tokens.
     * @param amounts_ Array of amounts that will be minted for each account.
     */
    function batchMint(
        address[] calldata accounts_,
        uint256[] calldata amounts_
    )
        external
        override
        onlyIssuerOrRegistrar
        whenNotPaused
        whenNotGlobalPaused
    {
        uint256 accountCount = accounts_.length;

        require(
            _status == Status.Live,
            "minting is not allowed when the contract is not live"
        );

        require(
            accountCount == amounts_.length,
            "Input arrays must have the same length"
        );

        (bool allWhitelisted, ) = Restrictions(_restrictionsSmartContract)
            .checkWhitelistStatus(accounts_);
        require(allWhitelisted, "one or more addresses is not whitelisted");

        for (uint256 i = 0; i < accountCount; ++i) {
            _mint(accounts_[i], amounts_[i]);
        }
        emit BatchMint(accounts_, amounts_);
    }

    /**
     * @dev Add an issuer with the necessary roles.
     * @param issuer_ The address of the new issuer.
     */
    function addIssuer(
        address issuer_
    )
        external
        override
        onlyIssuerOrRegistrar
        whenNotPaused
        whenNotGlobalPaused
    {
        require(
            Restrictions(_restrictionsSmartContract).isWhitelisted(issuer_),
            "account is not whitelisted"
        );

        _grantIssuerRoles(issuer_);
    }

    /**
     * @dev Remove an issuer role of an account.
     * @param issuer_ The account to remove the issuer role.
     */
    function removeIssuer(address issuer_) external onlyRegistrar {
        require(
            hasRole(ISSUER, issuer_),
            "cannot remove role, account is not an issuer"
        );
        _revokeRole(ISSUER, issuer_);
        _revokeRole(ISSUER_ADMIN, issuer_);
    }

    /**
     * @dev checks if an escrow address is part of the mapping or not
     * @param escrow_ The account to check the address of in the mapping.
     */

    function isEscrow(address escrow_) external view returns (bool) {
        return _redemptionEscrowContracts[escrow_];
    }
    /**
     * @dev Add a contract from the mapping of escrow contracts which can transfer tokens after maturity.
     * @param escrow_ The account to add the address to the mapping.
     * Event emitted with the escrow address and string to show "added"
     */
    function addEscrow(address escrow_) external onlyIssuerOrRegistrar {
        _redemptionEscrowContracts[escrow_] = true;

        emit EscrowListChanged(escrow_, "added");
    }
    /**
     * @dev Remove a contract from the mapping of escrow contracts which can transfer tokens after maturity.
     * @param escrow_ The account to remove the address from the mapping.
     * Event emitted with the escrow address and string to show "removed"
     */
    function removeEscrow(address escrow_) external onlyIssuerOrRegistrar {
        _redemptionEscrowContracts[escrow_] = false;
        emit EscrowListChanged(escrow_, "removed");
    }

    /**
     * @dev Internal function to grant issuer roles to an account.
     * @param account_ The address to grant issuer roles to.
     */
    function _grantIssuerRoles(address account_) internal {
        _grantRole(ISSUER, account_);
        _grantRole(ISSUER_ADMIN, account_);
    }

    // ERC20 Functions

    /**
     * @dev Get the name of the security asset.
     * @return The name of the security asset.
     */
    function name()
        public
        view
        override(ERC20, IERC20Metadata)
        returns (string memory)
    {
        return _name;
    }

    /**
     * @dev Get the symbol of the security asset.
     * @return The symbol of the security asset.
     */
    function symbol()
        public
        view
        override(ERC20, IERC20Metadata)
        returns (string memory)
    {
        return _symbol;
    }

    /**
     * @dev Get the number of decimals for the security asset.
     * @return The number of decimals.
     */
    function decimals()
        public
        view
        override(ERC20, IERC20Metadata)
        returns (uint8)
    {
        return _decimals;
    }

    /**
     * @dev Transfer tokens to a recipient address. If the status is live you can transfer to any whitelisted address, if the status is matured you can transfer only to the issuer or an escrow contract.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     * @return A boolean indicating whether the transfer was successful.
     */
    function transfer(
        address to,
        uint256 amount
    )
        public
        override(ERC20, IERC20)
        whenNotPaused
        whenNotGlobalPaused
        returns (bool)
    {
        if (_status == Status.Live) {
            require(
                Restrictions(_restrictionsSmartContract).isWhitelisted(
                    msg.sender
                ),
                "Your account is not whitelisted"
            );
            require(
                Restrictions(_restrictionsSmartContract).isWhitelisted(to),
                "recipient is not whitelisted"
            );
            require(
                amount % _minimumDenomination == 0,
                "amount must be multiple of minimumDenomination value"
            );
            _transfer(msg.sender, to, amount);

            return true;
        } else if (_status == Status.Matured) {
            require(
                Restrictions(_restrictionsSmartContract).isWhitelisted(
                    msg.sender
                ),
                "Your account is not whitelisted"
            );
            require(
                amount % _minimumDenomination == 0,
                "amount must be multiple of minimumDenomination value"
            );
            require(
                to == _issuer || _redemptionEscrowContracts[to],
                "the address must be the issuer or an authorised escrow contract"
            );
            _transfer(msg.sender, to, amount);

            return true;
        } else {
            revert("contract must be in live or matured state");
        }
    }

    /**
     * @dev Transfer tokens from a sender to a recipient address. If the status is live you can transfer to any whitelisted address,
     * if the status is matured you can transfer only to the issuer or an escrow contract.
     * @param recipient The address to transfer tokens to.
     * @param sender The address to transfer tokens from.
     * @param amount The amount of tokens to transfer.
     * @return A boolean indicating whether the transfer was successful.
     */

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        override(ERC20, IERC20)
        // onlyIssuerOrRegistrar
        whenNotPaused
        whenNotGlobalPaused
        returns (bool)
    {
        if (_status == Status.Live) {
            require(
                Restrictions(_restrictionsSmartContract).isWhitelisted(sender),
                "Sender is not whitelisted"
            );
            require(
                Restrictions(_restrictionsSmartContract).isWhitelisted(
                    recipient
                ),
                "recipient is not whitelisted"
            );
            _transfer(sender, recipient, amount);

            return true;
        } else if (_status == Status.Matured) {
            require(
                Restrictions(_restrictionsSmartContract).isWhitelisted(sender),
                "Your account is not whitelisted"
            );
            require(
                Restrictions(_restrictionsSmartContract).isWhitelisted(
                    recipient
                ),
                "recipient is not whitelisted"
            );

            require(
                recipient == _issuer || _redemptionEscrowContracts[recipient],
                "the address must be the issuer or an authorised escrow contract"
            );
            _transfer(sender, recipient, amount);

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Get the balance of tokens for a specific account.
     * @param account The address of the account.
     * @return The balance of tokens.
     */
    function balanceOf(
        address account
    ) public view override(ERC20, IERC20) returns (uint256) {
        if (_status == Status.Closed) {
            if (account == _issuer) {
                return totalSupply();
            }
            return 0;
        }
        return super.balanceOf(account);
    }

    // Getters

    /**
     * @dev Get the security type of the security asset.
     * @return The security type, which can be either CustomSecurityAsset or Bond.
     */
    function securityType() external view returns (Type) {
        return _securityType;
    }

    /**
     * @dev Get the ISIN (International Securities Identification Number) of the security asset.
     * @return The ISIN of the security asset.
     */
    function isin() external view returns (string memory) {
        return _isin;
    }

    /**
     * @dev Get the currency of the security asset.
     * @return The currency of the security asset.
     */
    function currency() external view returns (string memory) {
        return _currency;
    }

    /**
     * @dev Get the maturity date of the security asset.
     * @return The maturity date of the security asset.
     */
    function maturity() external view returns (string memory) {
        return _maturity;
    }

    /**
     * @dev Get the minimum denomination of the security asset.
     * @return The minimum denomination of the security asset.
     */
    function minimumDenomination() external view returns (uint64) {
        return _minimumDenomination;
    }

    /**
     * @dev Get the additional information URI of the security asset.
     * @return The additional information URI of the security asset.
     */
    function addInfoUri() external view returns (string memory) {
        return _addInfoUri;
    }

    /**
     * @dev Get the checksum of the security asset.
     * @return The checksum of the security asset.
     */
    function checksum() external view returns (string memory) {
        return _checksum;
    }

    /**
     * @dev Get the address of the restrictions smart contract associated with this security asset.
     * @return The address of the restrictions smart contract.
     */
    function restrictionsSmartContract() external view returns (address) {
        return _restrictionsSmartContract;
    }

    /**
     * @dev Get the status of the security asset.
     * @return The status, which can be Preliminary, Live, Matured, or Closed.
     */
    function status() external view returns (Status) {
        return _status;
    }

    /**
     * @dev Get the issuance country of the security asset.
     * @return The issuance country of the security asset.
     */
    function issuanceCountry() external view returns (string memory) {
        return _issuanceCountry;
    }

    /**
     * @dev Get the address of the issuer of the security asset.
     * @return The address of the issuer.
     */
    function issuer() external view returns (address) {
        return _issuer;
    }

    // Setters

    /**
     * @dev Set the ISIN (International Securities Identification Number) for the security asset.
     * @param isin_ The new ISIN to set.
     */
    function setISIN(string calldata isin_) external override onlyRegistrar {
        require(
            _status == Status.Preliminary,
            "contract is not in Preliminary status"
        );
        string memory oldValue = _isin;
        _isin = isin_;
        emit PropertyChanged("isin", "string", oldValue, _isin);
    }

    /**
     * @dev Set the checksum for the security asset.
     * @param checksum_ The new checksum to set.
     */
    function setChecksum(
        string calldata checksum_
    ) external override onlyRegistrar {
        require(
            _status == Status.Preliminary,
            "contract is not in Preliminary status"
        );
        string memory oldValue = _checksum;
        _checksum = checksum_;
        emit PropertyChanged("checksum", "string", oldValue, _checksum);
    }

    /**
     * @dev Set the security type for the security asset.
     * @param securityType_ The new security type to set.
     */
    function setSecurityType(
        Type securityType_
    ) external override onlyRegistrar {
        require(
            _status == Status.Preliminary,
            "contract is not in Preliminary status"
        );
        Type oldValue = _securityType;
        _securityType = securityType_;
        emit PropertyChanged(
            "securityType",
            "uint256",
            uint256(oldValue),
            uint256(_securityType)
        );
    }

    /**
     * @dev Set the maturity date for the security asset.
     * @param maturity_ The new maturity date to set.
     */
    function setMaturity(string calldata maturity_) external onlyRegistrar {
        require(
            _status == Status.Preliminary,
            "contract is not in Preliminary status"
        );
        string memory oldValue = _maturity;
        _maturity = maturity_;
        emit PropertyChanged("maturity", "string", oldValue, _maturity);
    }

    /**
     * @dev Set the minimum denomination for the security asset.
     * @param minimumDenomination_ The new minimum denomination to set.
     */
    function setMinimumDenomination(
        uint64 minimumDenomination_
    ) external onlyRegistrar {
        require(
            _status == Status.Preliminary,
            "contract is not in Preliminary status"
        );
        uint64 oldValue = _minimumDenomination;
        _minimumDenomination = minimumDenomination_;
        emit PropertyChanged(
            "minimumDenomination",
            "uint64",
            oldValue,
            _minimumDenomination
        );
    }

    /**
     * @dev Set the additional information URI for the security asset.
     * @param addInfoUri_ The new additional information URI to set.
     */
    function setAddInfoUri(
        string calldata addInfoUri_
    ) external override onlyRegistrar {
        require(
            _status == Status.Preliminary,
            "contract is not in Preliminary status"
        );
        string memory oldValue = _addInfoUri;
        _addInfoUri = addInfoUri_;
        emit PropertyChanged("addInfoUri", "string", oldValue, _addInfoUri);
    }

    /**
     * @dev Set the issuance country for the security asset.
     * @param issuanceCountry_ The new issuance country to set.
     */
    function setIssuanceCountry(
        string calldata issuanceCountry_
    ) external override onlyRegistrar {
        require(
            _status == Status.Preliminary,
            "contract is not in Preliminary status"
        );
        string memory oldValue = _issuanceCountry;
        _issuanceCountry = issuanceCountry_;
        emit PropertyChanged(
            "issuanceCountry",
            "string",
            oldValue,
            _issuanceCountry
        );
    }

    /**
     * @dev Set the currency for the security asset.
     * @param currency_ The new currency to set.
     */
    function setCurrency(
        string calldata currency_
    ) external override onlyRegistrar {
        require(
            _status == Status.Preliminary,
            "contract is not in Preliminary status"
        );
        string memory oldValue = _currency;
        _currency = currency_;
        emit PropertyChanged("currency", "string", oldValue, _currency);
    }

    /**
     * @dev Set the name for the security asset.
     * @param name_ The new name to set.
     */
    function setName(string calldata name_) external override onlyRegistrar {
        require(
            _status == Status.Preliminary,
            "contract is not in Preliminary status"
        );
        string memory oldValue = _name;
        _name = name_;
        emit PropertyChanged("name", "string", oldValue, _name);
    }

    /**
     * @dev Set the symbol for the security asset.
     * @param symbol_ The new symbol to set.
     */
    function setSymbol(
        string calldata symbol_
    ) external override onlyRegistrar {
        require(
            _status == Status.Preliminary,
            "contract is not in Preliminary status"
        );
        string memory oldValue = _symbol;
        _symbol = symbol_;
        emit PropertyChanged("symbol", "string", oldValue, _symbol);
    }

    /**
     * @dev Set a new issuer for the security asset.
     * @param issuer_ The address of the new issuer.
     */
    function setIssuer(address issuer_) external override onlyRegistrar {
        require(
            _status == Status.Preliminary,
            "contract is not in Preliminary status"
        );
        address oldValue = _issuer;
        _issuer = issuer_;
        emit PropertyChanged("issuer", "address", oldValue, _issuer);
    }

    // Change status

    /**
     * @dev Change the status of the security asset to "Live".
     */
    function setLive() external onlyRegistrar {
        Status oldStatus = _status;
        _status = Status.Live;
        emit ChangeStatus(oldStatus, _status);
    }

    /**
     * @dev Change the status of the security asset to "Matured".
     */
    function setMatured() external onlyRegistrar {
        Status oldStatus = _status;
        _status = Status.Matured;
        emit ChangeStatus(oldStatus, _status);
    }

    /**
     * @dev Change the status of the security asset to "Closed".
     */
    function setClosed() external onlyRegistrar {
        Status oldStatus = _status;
        _status = Status.Closed;
        emit ChangeStatus(oldStatus, _status);
    }

    // Pause

    /**
     * @dev Pause all functionality of the security asset contract.
     */
    function pause() external onlyRegistrar {
        _pause();
    }

    /**
     * @dev Unpause all functionality of the security asset contract.
     */
    function unpause() external onlyRegistrar {
        _unpause();
    }
}
