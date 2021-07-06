// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../specs/IZoraOverride.sol";

/**
 * @dev Implementation of Zora override
 */
contract ZoraOverride is IZoraOverride, ERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IZoraOverride).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IZoraOverride.convertBidShares}.
     */
    function convertBidShares(address media, uint256 tokenId) public view override returns (address payable[] memory receivers, uint256[] memory bps) {
        IZoraMarket.ZoraBidShares memory bidShares = IZoraMarket(IZoraMedia(media).marketContract()).bidSharesForToken(tokenId);

        // Get the total length of receivers/bps
        uint256 totalLength = 0;

        // Note: We do not support previous owner bps because it requires recalculation/sell-on support
        // Only Zora marketplace does this properly
        // if (bidShares.prevOwner.value != 0) totalLength++;

        if (bidShares.creator.value != 0) totalLength++;
        if (bidShares.owner.value != 0) totalLength++;

        receivers = new address payable[](totalLength);
        bps = new uint256[](totalLength);

        uint256 currentIndex = 0;
        if (bidShares.creator.value != 0) {
            receivers[currentIndex] = payable(IZoraMedia(media).tokenCreators(tokenId));
            bps[currentIndex] = bidShares.creator.value/(10**(18-2));
            currentIndex++;
        }
        if (bidShares.owner.value != 0) {
            receivers[currentIndex] = payable(IZoraMedia(media).ownerOf(tokenId));
            bps[currentIndex] = bidShares.owner.value/(10**(18-2));
            currentIndex++;
        }
        return (receivers, bps);
    }
    

}