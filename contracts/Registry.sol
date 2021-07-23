// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./specs/IManifold.sol";
import "./specs/IRarible.sol";
import "./specs/IFoundation.sol";
import "./specs/IEIP2981.sol";
import "./specs/IZoraOverride.sol";
import "./IRegistry.sol";

/**
 * @dev Registry to lookup royalty configurations
 */
contract Registry is ERC165, OwnableUpgradeable, IRegistry {
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
        return interfaceId == type(IRegistry).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IRegistry-overrideAddress}.
     */
    function overrideAddress(address tokenAddress, address royaltyAddress) public override {
        require(tokenAddress.isContract() && royaltyAddress.isContract(), "Invalid input");
        require(owner() == _msgSender() || OwnableUpgradeable(tokenAddress).owner() == _msgSender(), "Must be contract owner to override");
        _overrides[tokenAddress] = royaltyAddress;
        emit RoyaltyOverride(_msgSender(), tokenAddress, royaltyAddress);
    }

    /**
     * @dev See {IRegistry-getRoyalty}.
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) public view override returns(address payable[] memory recipients, uint256[] memory amounts) {
        address originalTokenAddress = tokenAddress;

        // Use override if configured
        if (_overrides[tokenAddress] != address(0)) tokenAddress = _overrides[tokenAddress];

        if (ERC165Checker.supportsInterface(tokenAddress, type(IManifold).interfaceId)) {
            // Supports manifold interface.  Compute amounts
            uint256[] memory bps;
            (recipients, bps) = IManifold(tokenAddress).getRoyalties(tokenId);
            require(recipients.length == bps.length);
            return (recipients, _computeAmounts(value, bps));
        } else if (ERC165Checker.supportsInterface(tokenAddress, type(IRaribleV2).interfaceId)) {
            // Supports rarible v2 interface. Compute amounts
            IRaribleV2.Part[] memory royalties = IRaribleV2(tokenAddress).getRaribleV2Royalties(tokenId);
            recipients = new address payable[](royalties.length);
            amounts = new uint256[](royalties.length);
            for (uint i = 0; i < royalties.length; i++) {
                recipients[i] = royalties[i].account;
                amounts[i] = value*royalties[i].value/10000;
            }
            return (recipients, amounts);
        } else if (ERC165Checker.supportsInterface(tokenAddress, type(IRaribleV1).interfaceId)) {
            // Supports rarible v1 interface. Compute amounts
            recipients = IRaribleV1(tokenAddress).getFeeRecipients(tokenId);
            uint256[] memory bps = IRaribleV1(tokenAddress).getFeeBps(tokenId);
            require(recipients.length == bps.length);
            return (recipients, _computeAmounts(value, bps));
        } else if (ERC165Checker.supportsInterface(tokenAddress, type(IFoundation).interfaceId)) {
            // Supports foundation interface.  Compute amounts
            uint256[] memory bps;
            (recipients, bps) = IFoundation(tokenAddress).getFees(tokenId);
            require(recipients.length == bps.length);
            return (recipients, _computeAmounts(value, bps));
        } else if (ERC165Checker.supportsInterface(tokenAddress, type(IEIP2981).interfaceId)) {
            // Supports EIP2981.  Return amounts
            (address recipient, uint256 amount) = IEIP2981(tokenAddress).royaltyInfo(tokenId, value);
            recipients = new address payable[](1);
            amounts = new uint256[](1);
            recipients[0] = payable(recipient);
            amounts[0] = amount;
        } else if (ERC165Checker.supportsInterface(tokenAddress, type(IZoraOverride).interfaceId)) {
            // Support Zora override
            uint256[] memory bps;
            (recipients, bps) = IZoraOverride(tokenAddress).convertBidShares(originalTokenAddress, tokenId);
            return (recipients, _computeAmounts(value, bps));
        }
        return (recipients, amounts);
    }

    /**
     * Compute royalty amounts
     */
    function _computeAmounts(uint256 value, uint256[] memory bps) private pure returns(uint256[] memory amounts) {
        amounts = new uint256[](bps.length);
        for (uint i = 0; i < bps.length; i++) {
            amounts[i] = value*bps[i]/10000;
        }
        return amounts;
    }


}