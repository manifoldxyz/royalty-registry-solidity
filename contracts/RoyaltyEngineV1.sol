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
import "./IRoyaltyEngineV1.sol";
import "./IRoyaltyRegistry.sol";

/**
 * @dev Engine to lookup royalty configurations
 */
contract RoyaltyEngineV1 is ERC165, OwnableUpgradeable, IRoyaltyEngineV1 {
    using AddressUpgradeable for address;

    address public royaltyRegistry;

    function initialize(address royaltyRegistry_) public initializer {
        __Ownable_init_unchained();
        require(ERC165Checker.supportsInterface(royaltyRegistry_, type(IRoyaltyRegistry).interfaceId));
        royaltyRegistry = royaltyRegistry_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRoyaltyEngineV1).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IRegistry-getRoyalty}.
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) public view override returns(address payable[] memory recipients, uint256[] memory amounts) {
        address royaltyAddress = IRoyaltyRegistry(royaltyRegistry).getRoyaltyLookupAddress(tokenAddress);

        try IManifold(royaltyAddress).getRoyalties(tokenId) returns(address payable[] memory recipients_, uint256[] memory bps) {
            // Supports manifold interface.  Compute amounts
            require(recipients_.length == bps.length);
            return (recipients_, _computeAmounts(value, bps));
        } catch {}
        try IRaribleV2(royaltyAddress).getRaribleV2Royalties(tokenId) returns(IRaribleV2.Part[] memory royalties) {
            // Supports rarible v2 interface. Compute amounts
            recipients = new address payable[](royalties.length);
            amounts = new uint256[](royalties.length);
            for (uint i = 0; i < royalties.length; i++) {
                recipients[i] = royalties[i].account;
                amounts[i] = value*royalties[i].value/10000;
            }
            return (recipients, amounts);
        } catch {}
        try IRaribleV1(royaltyAddress).getFeeRecipients(tokenId) returns(address payable[] memory recipients_) {
            // Supports rarible v1 interface. Compute amounts
            recipients_ = IRaribleV1(royaltyAddress).getFeeRecipients(tokenId);
            try IRaribleV1(royaltyAddress).getFeeBps(tokenId) returns (uint256[] memory bps) {
                require(recipients_.length == bps.length);
                return (recipients_, _computeAmounts(value, bps));
            } catch {}
        } catch {}
        try IFoundation(royaltyAddress).getFees(tokenId) returns(address payable[] memory recipients_, uint256[] memory bps) {
            // Supports foundation interface.  Compute amounts
            require(recipients_.length == bps.length);
            return (recipients_, _computeAmounts(value, bps));
        } catch {}
        try IEIP2981(royaltyAddress).royaltyInfo(tokenId, value) returns(address recipient, uint256 amount) {
            // Supports EIP2981.  Return amounts
            recipients = new address payable[](1);
            amounts = new uint256[](1);
            recipients[0] = payable(recipient);
            amounts[0] = amount;
            return (recipients, amounts);
        } catch {}
        try IZoraOverride(royaltyAddress).convertBidShares(tokenAddress, tokenId) returns(address payable[] memory recipients_, uint256[] memory bps) {
            // Support Zora override
            return (recipients_, _computeAmounts(value, bps));
        } catch {}
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