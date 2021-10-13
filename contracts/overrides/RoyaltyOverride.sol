// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../specs/IEIP2981.sol";

/**
 * Simple EIP2981 reference override implementation
 */
contract EIP2981RoyaltyOverride is IEIP2981, Ownable, ERC165 {

    event TokenRoyaltySet(uint256 tokenId, address recipient, uint16 bps);
    event DefaultRoyaltySet(address recipient, uint16 bps);

    struct TokenRoyalty {
        address recipient;
        uint16 bps;
    }

    TokenRoyalty private _defaultRoyalty;
    mapping(uint256 => TokenRoyalty) private _tokenRoyalties;

    function setTokenRoyalty(uint256 tokenId, address recipient, uint16 bps) public onlyOwner {
        _tokenRoyalties[tokenId] = TokenRoyalty(recipient, bps);
        emit TokenRoyaltySet(tokenId, recipient, bps);
    }

    function setDefaultRoyalty(address recipient, uint16 bps) public onlyOwner {
        _defaultRoyalty = TokenRoyalty(recipient, bps);
        emit DefaultRoyaltySet(recipient, bps);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 value) public override view returns (address, uint256) {
        if (_tokenRoyalties[tokenId].recipient != address(0)) {
            return (_tokenRoyalties[tokenId].recipient, value*_tokenRoyalties[tokenId].bps/10000);
        }
        if (_defaultRoyalty.recipient != address(0) && _defaultRoyalty.bps != 0) {
            return (_defaultRoyalty.recipient, value*_defaultRoyalty.bps/10000);
        }
        return (address(0), 0);
    }
}
