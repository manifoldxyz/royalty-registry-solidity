// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./libraries/SuperRareContracts.sol";

import "./specs/IManifold.sol";
import "./specs/IRarible.sol";
import "./specs/IFoundation.sol";
import "./specs/ISuperRare.sol";
import "./specs/IEIP2981.sol";
import "./specs/IZoraOverride.sol";
import "./specs/IArtBlocksOverride.sol";
import "./IRoyaltyEngineV1.sol";
import "./IRoyaltyRegistry.sol";

/**
 * @dev Engine to lookup royalty configurations
 */
contract RoyaltyEngineV1 is ERC165, OwnableUpgradeable, IRoyaltyEngineV1 {
    using AddressUpgradeable for address;

    // Use int16 for specs to support future spec additions
    // When we add a spec, we also decrement the NONE value
    // Anything > NONE and <= NOT_CONFIGURED is considered not configured
    int16 constant private NONE = -1;
    int16 constant private NOT_CONFIGURED = 0;
    int16 constant private MANIFOLD = 1;
    int16 constant private RARIBLEV1 = 2;
    int16 constant private RARIBLEV2 = 3;
    int16 constant private FOUNDATION = 4;
    int16 constant private EIP2981 = 5;
    int16 constant private SUPERRARE = 6;
    int16 constant private ZORA = 7;
    int16 constant private ARTBLOCKS = 8;

    mapping (address => int16) _specCache;

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
     * @dev See {IRoyaltyEngineV1-getRoyalty}
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) public override returns(address payable[] memory recipients, uint256[] memory amounts) {
        int16 spec;
        address royaltyAddress;
        bool addToCache;

        (recipients, amounts, spec, royaltyAddress, addToCache) = _getRoyaltyAndSpec(tokenAddress, tokenId, value);
        if (addToCache) _specCache[royaltyAddress] = spec;
        return (recipients, amounts);
    }

    /**
     * @dev See {IRoyaltyEngineV1-getRoyaltyView}.
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) public view override returns(address payable[] memory recipients, uint256[] memory amounts) {
        (recipients, amounts, , , ) = _getRoyaltyAndSpec(tokenAddress, tokenId, value);
        return (recipients, amounts);
    }

    /**
     * @dev Get the royalty and royalty spec for a given token
     * 
     * returns recipieints array, amounts array, royalty spec, royalty address, whether or not to add to cache
     */
    function _getRoyaltyAndSpec(address tokenAddress, uint256 tokenId, uint256 value) private view returns(address payable[] memory recipients, uint256[] memory amounts, int16 spec, address royaltyAddress, bool addToCache) {

        royaltyAddress = IRoyaltyRegistry(royaltyRegistry).getRoyaltyLookupAddress(tokenAddress);
        spec = _specCache[royaltyAddress];

        if (spec <= NOT_CONFIGURED && spec > NONE) {
            // No spec configured yet, so we need to detect the spec
            addToCache = true;

            // SuperRare handling
            if (tokenAddress == SuperRareContracts.SUPERRARE_V1 || tokenAddress == SuperRareContracts.SUPERRARE_V2) {
                try ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY).tokenCreator(tokenAddress, tokenId) returns(address payable creator) {
                    try ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY).calculateRoyaltyFee(tokenAddress, tokenId, value) returns(uint256 amount) {
                        recipients = new address payable[](1);
                        amounts = new uint256[](1);
                        recipients[0] = creator;
                        amounts[0] = amount;
                        return (recipients, amounts, SUPERRARE, royaltyAddress, addToCache);                        
                    } catch {}
                } catch {}
            }
            try IManifold(royaltyAddress).getRoyalties(tokenId) returns(address payable[] memory recipients_, uint256[] memory bps) {
                // Supports manifold interface.  Compute amounts
                require(recipients_.length == bps.length);
                return (recipients_, _computeAmounts(value, bps), MANIFOLD, royaltyAddress, addToCache);
            } catch {}
            try IRaribleV2(royaltyAddress).getRaribleV2Royalties(tokenId) returns(IRaribleV2.Part[] memory royalties) {
                // Supports rarible v2 interface. Compute amounts
                recipients = new address payable[](royalties.length);
                amounts = new uint256[](royalties.length);
                uint256 totalAmount;
                for (uint i = 0; i < royalties.length; i++) {
                    recipients[i] = royalties[i].account;
                    amounts[i] = value*royalties[i].value/10000;
                    totalAmount += amounts[i];
                }
                require(totalAmount < value, "Invalid royalty amount");
                return (recipients, amounts, RARIBLEV2, royaltyAddress, addToCache);
            } catch {}
            try IRaribleV1(royaltyAddress).getFeeRecipients(tokenId) returns(address payable[] memory recipients_) {
                // Supports rarible v1 interface. Compute amounts
                recipients_ = IRaribleV1(royaltyAddress).getFeeRecipients(tokenId);
                try IRaribleV1(royaltyAddress).getFeeBps(tokenId) returns (uint256[] memory bps) {
                    require(recipients_.length == bps.length);
                    return (recipients_, _computeAmounts(value, bps), RARIBLEV1, royaltyAddress, addToCache);
                } catch {}
            } catch {}
            try IFoundation(royaltyAddress).getFees(tokenId) returns(address payable[] memory recipients_, uint256[] memory bps) {
                // Supports foundation interface.  Compute amounts
                require(recipients_.length == bps.length);
                return (recipients_, _computeAmounts(value, bps), FOUNDATION, royaltyAddress, addToCache);
            } catch {}
            try IEIP2981(royaltyAddress).royaltyInfo(tokenId, value) returns(address recipient, uint256 amount) {
                // Supports EIP2981.  Return amounts
                require(amount < value, "Invalid royalty amount");
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
                return (recipients, amounts, EIP2981, royaltyAddress, addToCache);
            } catch {}
            try IZoraOverride(royaltyAddress).convertBidShares(tokenAddress, tokenId) returns(address payable[] memory recipients_, uint256[] memory bps) {
                // Support Zora override
                require(recipients_.length == bps.length);
                return (recipients_, _computeAmounts(value, bps), ZORA, royaltyAddress, addToCache);
            } catch {}
            try IArtBlocksOverride(royaltyAddress).getRoyalties(tokenAddress, tokenId) returns(address payable[] memory recipients_, uint256[] memory bps) {
                // Support Art Blocks override
                require(recipients_.length == bps.length);
                return (recipients_, _computeAmounts(value, bps), ARTBLOCKS, royaltyAddress, addToCache);
            } catch {}

            // No supported royalties configured
            return (recipients, amounts, NONE, royaltyAddress, addToCache);
        } else {
            // Spec exists, just execute the appropriate one
            addToCache = false;
            if (spec == NONE) {
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            } else if (spec == MANIFOLD) {
                // Manifold spec
                uint256[] memory bps;
                (recipients, bps) = IManifold(royaltyAddress).getRoyalties(tokenId);
                require(recipients.length == bps.length);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == RARIBLEV2) {
                // Rarible v2 spec
                IRaribleV2.Part[] memory royalties;
                royalties = IRaribleV2(royaltyAddress).getRaribleV2Royalties(tokenId);
                recipients = new address payable[](royalties.length);
                amounts = new uint256[](royalties.length);
                uint256 totalAmount;
                for (uint i = 0; i < royalties.length; i++) {
                    recipients[i] = royalties[i].account;
                    amounts[i] = value*royalties[i].value/10000;
                    totalAmount += amounts[i];
                }
                require(totalAmount < value, "Invalid royalty amount");
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            } else if (spec == RARIBLEV1) {
                // Rarible v1 spec
                uint256[] memory bps;
                recipients = IRaribleV1(royaltyAddress).getFeeRecipients(tokenId);
                bps = IRaribleV1(royaltyAddress).getFeeBps(tokenId);
                require(recipients.length == bps.length);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == FOUNDATION) {
                // Foundation spec
                uint256[] memory bps;
                (recipients, bps) = IFoundation(royaltyAddress).getFees(tokenId);
                require(recipients.length == bps.length);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == EIP2981) {
                // EIP2981 spec
                (address recipient, uint256 amount) = IEIP2981(royaltyAddress).royaltyInfo(tokenId, value);
                require(amount < value, "Invalid royalty amount");
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            } else if (spec == SUPERRARE) {
                // SUPERRARE spec
                address payable creator = ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY).tokenCreator(tokenAddress, tokenId);
                uint256 amount = ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY).calculateRoyaltyFee(tokenAddress, tokenId, value);
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = creator;
                amounts[0] = amount;
                return (recipients, amounts, spec, royaltyAddress, addToCache);            
            } else if (spec == ZORA) {
                // Zora spec
                uint256[] memory bps;
                (recipients, bps) = IZoraOverride(royaltyAddress).convertBidShares(tokenAddress, tokenId);
                require(recipients.length == bps.length);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);          
            } else if (spec == ARTBLOCKS) {
                // Art Blocks spec
                uint256[] memory bps;
                (recipients, bps) = IArtBlocksOverride(royaltyAddress).getRoyalties(tokenAddress, tokenId);
                require(recipients.length == bps.length);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            }
        }
    }

    /**
     * Compute royalty amounts
     */
    function _computeAmounts(uint256 value, uint256[] memory bps) private pure returns(uint256[] memory amounts) {
        amounts = new uint256[](bps.length);
        uint256 totalAmount;
        for (uint i = 0; i < bps.length; i++) {
            amounts[i] = value*bps[i]/10000;
            totalAmount += amounts[i];
        }
        require(totalAmount < value, "Invalid royalty amount");
        return amounts;
    }


}