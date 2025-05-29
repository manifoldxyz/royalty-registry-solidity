// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import { ERC165, IERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import { IManifold } from "./specs/IManifold.sol";
import { IRaribleV2 } from "./specs/IRarible.sol";
import { IEIP2981 } from "./specs/IEIP2981.sol";
import { IRoyaltyEngineV1 } from "./IRoyaltyEngineV1.sol";
import { IRoyaltySplitter, Recipient } from "./overrides/IRoyaltySplitter.sol";
/**
 * @dev Engine to lookup royalty configurations
 * For use on new chains that existed after EIP2981 was introduced and adopted
 * Only supports EIP2981, Manifold, Rarible V2, and Royalty Splitter
 */

contract RoyaltyEngineV2 is ERC165, IRoyaltyEngineV1 {
    // Use int16 for specs to support future spec additions
    // When we add a spec, we also decrement the NONE value
    // Anything > NONE and <= NOT_CONFIGURED is considered not configured
    int16 private constant NONE = -1;
    int16 private constant NOT_CONFIGURED = 0;
    int16 private constant MANIFOLD = 1;
    int16 private constant EIP2981 = 2;
    int16 private constant RARIBLEV2 = 3;
    int16 private constant ROYALTY_SPLITTER = 4;

    mapping(address => int16) _specCache;

    address public royaltyRegistry;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRoyaltyEngineV1).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Invalidate the cached spec (useful for situations where tooken royalty implementation changes to a different spec)
     */
    function invalidateCachedRoyaltySpec(address[] memory tokenAddresses) public {
        for (uint256 i; i < tokenAddresses.length;) {
            delete _specCache[tokenAddresses[i]];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev View function to get the cached spec of a token
     */
    function getCachedRoyaltySpec(address tokenAddress) public view returns (int16) {
        return _specCache[tokenAddress];
    }

    /**
     * @dev See {IRoyaltyEngineV1-getRoyalty}
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value)
        public
        override
        returns (address payable[] memory recipients, uint256[] memory amounts)
    {
        // External call to limit gas
        try this._getRoyaltyAndSpec{ gas: 75000 }(tokenAddress, tokenId, value) returns (
            address payable[] memory _recipients, uint256[] memory _amounts, int16 spec, bool addToCache
        ) {
            if (addToCache) _specCache[tokenAddress] = spec;
            return (_recipients, _amounts);
        } catch {
            revert("Invalid royalty amount");
        }
    }

    /**
     * @dev See {IRoyaltyEngineV1-getRoyaltyView}.
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value)
        public
        view
        override
        returns (address payable[] memory recipients, uint256[] memory amounts)
    {
        // External call to limit gas
        try this._getRoyaltyAndSpec{ gas: 75000 }(tokenAddress, tokenId, value) returns (
            address payable[] memory _recipients, uint256[] memory _amounts, int16, bool
        ) {
            return (_recipients, _amounts);
        } catch {
            revert("Invalid royalty amount");
        }
    }

    /**
     * @dev Get the royalty and royalty spec for a given token
     *
     * returns recipients array, amounts array, royalty spec, royalty address, whether or not to add to cache
     */
    function _getRoyaltyAndSpec(address tokenAddress, uint256 tokenId, uint256 value)
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts, int16 spec, bool addToCache)
    {
        require(msg.sender == address(this), "Only Engine");
        spec = _specCache[tokenAddress];

        if (spec <= NOT_CONFIGURED && spec > NONE) {
            // No spec configured yet, so we need to detect the spec
            addToCache = true;

            try IEIP2981(tokenAddress).royaltyInfo(tokenId, value) returns (address recipient, uint256 amount) {
                require(amount < value, "Invalid royalty amount");
                uint32 recipientSize;
                assembly {
                    recipientSize := extcodesize(recipient)
                }
                if (recipientSize > 0) {
                    try IRoyaltySplitter(recipient).getRecipients() returns (Recipient[] memory splitRecipients) {
                        recipients = new address payable[](splitRecipients.length);
                        amounts = new uint256[](splitRecipients.length);
                        uint256 sum = 0;
                        uint256 splitRecipientsLength = splitRecipients.length;
                        for (uint256 i = 0; i < splitRecipientsLength;) {
                            Recipient memory splitRecipient = splitRecipients[i];
                            recipients[i] = payable(splitRecipient.recipient);
                            uint256 splitAmount = splitRecipient.bps * amount / 10000;
                            amounts[i] = splitAmount;
                            sum += splitAmount;
                            unchecked {
                                ++i;
                            }
                        }
                        // sum can be less than amount, otherwise small-value listings can break
                        require(sum <= amount, "Invalid split");

                        return (recipients, amounts, ROYALTY_SPLITTER, addToCache);
                    } catch { }
                }
                // Supports EIP2981.  Return amounts
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
                return (recipients, amounts, EIP2981, addToCache);
            } catch { }
            try IManifold(tokenAddress).getRoyalties(tokenId) returns (
                address payable[] memory recipients_, uint256[] memory bps
            ) {
                // Supports manifold interface.  Compute amounts
                require(recipients_.length == bps.length);
                return (recipients_, _computeAmounts(value, bps), MANIFOLD, addToCache);
            } catch { }
            try IRaribleV2(tokenAddress).getRaribleV2Royalties(tokenId) returns (IRaribleV2.Part[] memory royalties) {
                // Supports rarible v2 interface. Compute amounts
                recipients = new address payable[](royalties.length);
                amounts = new uint256[](royalties.length);
                uint256 totalAmount;
                for (uint256 i = 0; i < royalties.length; i++) {
                    recipients[i] = royalties[i].account;
                    amounts[i] = value * royalties[i].value / 10000;
                    totalAmount += amounts[i];
                }
                require(totalAmount < value, "Invalid royalty amount");
                return (recipients, amounts, RARIBLEV2, addToCache);
            } catch { }

            // No supported royalties configured
            return (recipients, amounts, NONE, addToCache);
        } else {
            // Spec exists, just execute the appropriate one
            addToCache = false;
            if (spec == NONE) {
                return (recipients, amounts, spec, addToCache);
            } else if (spec == MANIFOLD) {
                // Manifold spec
                uint256[] memory bps;
                (recipients, bps) = IManifold(tokenAddress).getRoyalties(tokenId);
                require(recipients.length == bps.length);
                return (recipients, _computeAmounts(value, bps), spec, addToCache);
            } else if (spec == RARIBLEV2) {
                // Rarible v2 spec
                IRaribleV2.Part[] memory royalties;
                royalties = IRaribleV2(tokenAddress).getRaribleV2Royalties(tokenId);
                recipients = new address payable[](royalties.length);
                amounts = new uint256[](royalties.length);
                uint256 totalAmount;
                for (uint256 i = 0; i < royalties.length; i++) {
                    recipients[i] = royalties[i].account;
                    amounts[i] = value * royalties[i].value / 10000;
                    totalAmount += amounts[i];
                }
                require(totalAmount < value, "Invalid royalty amount");
                return (recipients, amounts, spec, addToCache);
            } else if (spec == EIP2981 || spec == ROYALTY_SPLITTER) {
                // EIP2981 spec
                (address recipient, uint256 amount) = IEIP2981(tokenAddress).royaltyInfo(tokenId, value);
                require(amount < value, "Invalid royalty amount");
                if (spec == ROYALTY_SPLITTER) {
                    Recipient[] memory splitRecipients = IRoyaltySplitter(recipient).getRecipients();
                    recipients = new address payable[](splitRecipients.length);
                    amounts = new uint256[](splitRecipients.length);
                    uint256 sum = 0;
                    uint256 splitRecipientsLength = splitRecipients.length;
                    for (uint256 i = 0; i < splitRecipientsLength;) {
                        Recipient memory splitRecipient = splitRecipients[i];
                        recipients[i] = payable(splitRecipient.recipient);
                        uint256 splitAmount = splitRecipient.bps * amount / 10000;
                        amounts[i] = splitAmount;
                        sum += splitAmount;
                        unchecked {
                            ++i;
                        }
                    }
                    // sum can be less than amount, otherwise small-value listings can break
                    require(sum <= value, "Invalid split");

                    return (recipients, amounts, spec, addToCache);
                }
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
                return (recipients, amounts, spec, addToCache);
            }
        }
    }

    /**
     * Compute royalty amounts
     */
    function _computeAmounts(uint256 value, uint256[] memory bps) private pure returns (uint256[] memory amounts) {
        amounts = new uint256[](bps.length);
        uint256 totalAmount;
        for (uint256 i = 0; i < bps.length; i++) {
            amounts[i] = value * bps[i] / 10000;
            totalAmount += amounts[i];
        }
        require(totalAmount < value, "Invalid royalty amount");
        return amounts;
    }
}
