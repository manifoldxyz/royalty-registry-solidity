// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "../overrides/RoyaltyOverrideCore.sol";

/**
 * Reference implementation of ERC1155 with EIP2981 support
 */
contract ERC1155WithEIP2981 is ERC1155, EIP2981RoyaltyOverrideCore, Ownable {

    constructor(string memory uri_) ERC1155(uri_) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, EIP2981RoyaltyOverrideCore) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId);
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