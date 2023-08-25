// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

import "./IRoyaltyRegistry.sol";
import "./specs/INiftyGateway.sol";
import "./specs/IFoundation.sol";
import "./specs/IDigitalax.sol";
import "./specs/IArtBlocks.sol";

/**
 * @dev Registry to lookup royalty configurations
 */
contract RoyaltyRegistry is ERC165, OwnableUpgradeable, IRoyaltyRegistry {
    using AddressUpgradeable for address;

    address public immutable OVERRIDE_FACTORY;

    /**
     * @notice Constructor arg allows efficient lookup of override factory for single-tx overrides.
     *         However, this means the RoyaltyRegistry will need to be upgraded if the override factory is changed.
     */
    constructor(address overrideFactory) {
        OVERRIDE_FACTORY = overrideFactory;
    }

    // Override addresses
    mapping(address => address) private _overrides;

    /**
     * @notice DO NOT USE! This gap exists due to a prior mapping
     *         that is no longer used.
     */
    mapping(address => address) private __gap_do_not_use_1;

    function initialize(address _initialOwner) public initializer {
        _transferOwnership(_initialOwner);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRoyaltyRegistry).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IRegistry-getRoyaltyLookupAddress}.
     */
    function getRoyaltyLookupAddress(address tokenAddress) external view override returns (address) {
        address override_ = _overrides[tokenAddress];
        if (override_ != address(0)) {
            return override_;
        }
        return tokenAddress;
    }

    /**
     * @dev See {IRegistry-setRoyaltyLookupAddress}.
     */
    function setRoyaltyLookupAddress(address tokenAddress, address royaltyLookupAddress)
        public
        override
        returns (bool)
    {
        require(
            tokenAddress.isContract() && (royaltyLookupAddress.isContract() || royaltyLookupAddress == address(0)),
            "Invalid input"
        );
        require(overrideAllowed(tokenAddress), "Permission denied");

        // set new override and reverse-lookup
        _overrides[tokenAddress] = royaltyLookupAddress;

        emit RoyaltyOverride(_msgSender(), tokenAddress, royaltyLookupAddress);
        return true;
    }

    /**
     * @dev See {IRegistry-overrideAllowed}.
     */
    function overrideAllowed(address tokenAddress) public view override returns (bool) {
        return _overrideAllowed(tokenAddress, _msgSender());
    }

    /**
     * @dev See {IRegistry-overrideAllowed}.
     */
    function overrideAllowed(address tokenAddress, address caller) external view override returns (bool) {
        return _overrideAllowed(tokenAddress, caller);
    }

    function _overrideAllowed(address tokenAddress, address caller) internal view returns (bool) {
        if (owner() == caller) return true;

        if (
            ERC165Checker.supportsInterface(tokenAddress, type(IAdminControl).interfaceId)
                && IAdminControl(tokenAddress).isAdmin(caller)
        ) {
            return true;
        }

        try OwnableUpgradeable(tokenAddress).owner() returns (address owner) {
            if (owner == caller) return true;

            if (owner.isContract()) {
                try OwnableUpgradeable(owner).owner() returns (address passThroughOwner) {
                    if (passThroughOwner == caller) return true;
                } catch { }
            }
        } catch { }

        try IAccessControlUpgradeable(tokenAddress).hasRole(0x00, caller) returns (bool hasRole) {
            if (hasRole) return true;
        } catch { }

        // Nifty Gateway overrides
        try INiftyBuilderInstance(tokenAddress).niftyRegistryContract() returns (address niftyRegistry) {
            try INiftyRegistry(niftyRegistry).isValidNiftySender(caller) returns (bool valid) {
                return valid;
            } catch { }
        } catch { }

        // OpenSea overrides
        // Tokens already support Ownable

        // Foundation overrides
        try IFoundationTreasuryNode(tokenAddress).getFoundationTreasury() returns (address payable foundationTreasury) {
            try IFoundationTreasury(foundationTreasury).isAdmin(caller) returns (bool isAdmin) {
                return isAdmin;
            } catch { }
        } catch { }

        // DIGITALAX overrides
        try IDigitalax(tokenAddress).accessControls() returns (address externalAccessControls) {
            try IDigitalaxAccessControls(externalAccessControls).hasAdminRole(caller) returns (bool hasRole) {
                if (hasRole) return true;
            } catch { }
        } catch { }

        // Art Blocks overrides
        try IArtBlocks(tokenAddress).admin() returns (address admin) {
            if (admin == caller) return true;
        } catch { }

        // Superrare overrides
        // Tokens and registry already support Ownable

        // Rarible overrides
        // Tokens already support Ownable

        return false;
    }

    function _msgSender() internal view virtual override(ContextUpgradeable) returns (address) {
        if (msg.sender == OVERRIDE_FACTORY) {
            address relayedSender;
            ///@solidity memory-safe-assembly
            assembly {
                // the factory appends the original msg.sender as last the word of calldata, which we can read using
                // calldataload
                relayedSender := calldataload(sub(calldatasize(), 0x20))
            }
            return relayedSender;
        }
        // otherwise return msg.sender as normal
        return msg.sender;
    }
}
