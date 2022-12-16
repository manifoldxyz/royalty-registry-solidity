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

    // Override addresses
    mapping (address => address) private _overrides;

    function initialize() public initializer {
        __Ownable_init_unchained();
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
    function getRoyaltyLookupAddress(address tokenAddress) external view override returns(address) {
        address override_ = _overrides[tokenAddress];
        if (override_ != address(0)) return override_;
        return tokenAddress;
    }

    /**
     * @dev See {IRegistry-setRoyaltyLookupAddress}.
     */
    function setRoyaltyLookupAddress(address tokenAddress, address royaltyLookupAddress) public override {
        require(tokenAddress.isContract() && (royaltyLookupAddress.isContract() || royaltyLookupAddress == address(0)), "Invalid input");
        address originatorAddress;
        if (_overrideAllowed(tx.origin, tokenAddress)) {
            originatorAddress = _msgSender();
        } else if (_overrideAllowed(_msgSender(), tokenAddress)) {
            originatorAddress = tx.origin;
        } else {
            revert("Permission denied");
        }
        _overrides[tokenAddress] = royaltyLookupAddress;
        emit RoyaltyOverride(originatorAddress, tokenAddress, royaltyLookupAddress);
    }

    /**
     * @dev See {IRegistry-overrideAllowed}.
     */
    function overrideAllowed(address tokenAddress) public view override returns(bool) {
        return _overrideAllowed(tx.origin, tokenAddress) || _overrideAllowed(_msgSender(), tokenAddress);
    }

    function _overrideAllowed(address senderAddress, address tokenAddress) private view returns(bool) {
        if (owner() == senderAddress) return true;

        if (ERC165Checker.supportsInterface(tokenAddress, type(IAdminControl).interfaceId)
            && IAdminControl(tokenAddress).isAdmin(senderAddress)) {
            return true;
        }

        try OwnableUpgradeable(tokenAddress).owner() returns (address owner) {
            if (owner == senderAddress) return true;

            if (owner.isContract()) {
              try OwnableUpgradeable(owner).owner() returns (address passThroughOwner) {
                  if (passThroughOwner == senderAddress) return true;
              } catch {}
            }
        } catch {}

        try IAccessControlUpgradeable(tokenAddress).hasRole(0x00, senderAddress) returns (bool hasRole) {
            if (hasRole) return true;
        } catch {}

        // Nifty Gateway overrides
        try INiftyBuilderInstance(tokenAddress).niftyRegistryContract() returns (address niftyRegistry) {
            try INiftyRegistry(niftyRegistry).isValidNiftySender(senderAddress) returns (bool valid) {
                return valid;
            } catch {}
        } catch {}

        // OpenSea overrides
        // Tokens already support Ownable

        // Foundation overrides
        try IFoundationTreasuryNode(tokenAddress).getFoundationTreasury() returns (address payable foundationTreasury) {
            try IFoundationTreasury(foundationTreasury).isAdmin(senderAddress) returns (bool isAdmin) {
                return isAdmin;
            } catch {}
        } catch {}

        // DIGITALAX overrides
        try IDigitalax(tokenAddress).accessControls() returns (address externalAccessControls){
            try IDigitalaxAccessControls(externalAccessControls).hasAdminRole(senderAddress) returns (bool hasRole) {
                if (hasRole) return true;
            } catch {}
        } catch {}

        // Art Blocks overrides
        try IArtBlocks(tokenAddress).admin() returns (address admin) {
            if (admin == senderAddress) return true;
        } catch {}

        // Superrare overrides
        // Tokens and registry already support Ownable

        // Rarible overrides
        // Tokens already support Ownable

        return false;
    }

}
