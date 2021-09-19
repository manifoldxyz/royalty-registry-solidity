// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./IRoyaltyRegistry.sol";

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
     * @dev See {IRegistry-overrideAddress}.
     */
    function overrideAddress(address tokenAddress, address royaltyAddress) public override {
        require(tokenAddress.isContract() && (royaltyAddress.isContract() || royaltyAddress == address(0)), "Invalid input");
        require(owner() == _msgSender() || OwnableUpgradeable(tokenAddress).owner() == _msgSender(), "Must be contract owner to override");
        _overrides[tokenAddress] = royaltyAddress;
        emit RoyaltyOverride(_msgSender(), tokenAddress, royaltyAddress);
    }

    /**
     * @dev See {IRegistry-getRoyaltyAddress}.
     */
    function getRoyaltyAddress(address tokenAddress) external view override returns(address) {
        address override_ = _overrides[tokenAddress];
        if (override_ != address(0)) return override_;
        return tokenAddress;
    }

}