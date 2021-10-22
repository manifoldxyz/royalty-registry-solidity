// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../overrides/RoyaltyOverrideCore.sol";

/**
 * Reference implementation of ERC721 with EIP2981 support
 */
contract ERC721WithEIP2981 is ERC721, EIP2981RoyaltyOverrideCore, Ownable {

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, EIP2981RoyaltyOverrideCore) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-setTokenRoyalties}.
     */
    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royaltyConfigs) external override onlyOwner {
        _setTokenRoyalties(royaltyConfigs);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-setDefaultRoyalty}.
     */
    function setDefaultRoyalty(TokenRoyalty calldata royalty) external override onlyOwner {
        _setDefaultRoyalty(royalty);
    }


}