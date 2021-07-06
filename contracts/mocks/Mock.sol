// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../specs/Manifold.sol";
import "../specs/Rarible.sol";
import "../specs/Foundation.sol";
import "../specs/EIP2981.sol";

/**
 * Does not implement any interface
 */
contract MockContract {
}


/**
 * Base template for royalty
 */
contract MockRoyalty is Ownable {
    mapping(uint256 => address payable[]) internal _receivers;
    mapping(uint256 => uint256[]) internal _bps;
    
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata bps) public {
        require(receivers.length == bps.length);
        _receivers[tokenId] = receivers;
        _bps[tokenId] = bps;
    }
}

/**
 * Implements Manifold interface
 */
contract MockManifold is IManifold, MockRoyalty, ERC165 {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IManifold).interfaceId || super.supportsInterface(interfaceId);
    }

    function getRoyalties(uint256 tokenId) public override view returns (address payable[] memory, uint256[] memory) {
        return (_receivers[tokenId], _bps[tokenId]);
    }   

}

/**
 * Implements Foundation interface
 */
contract MockFoundation is IFoundation, MockRoyalty, ERC165 {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IFoundation).interfaceId || super.supportsInterface(interfaceId);
    }

    function getFees(uint256 tokenId) public override view returns (address payable[] memory, uint256[] memory) {
        return (_receivers[tokenId], _bps[tokenId]);
    }   

}

/**
 * Implements RaribleV1 interface
 */
contract MockRaribleV1 is IRaribleV1, MockRoyalty, ERC165 {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IRaribleV1).interfaceId || super.supportsInterface(interfaceId);
    }

    function getFeeBps(uint256 tokenId) public override view returns (uint[] memory) {
        return _bps[tokenId];
    }   

    function getFeeRecipients(uint256 tokenId) public override view returns (address payable[] memory) {
        return _receivers[tokenId];
    }   

}

/**
 * Implements EIP2981 interface
 */
contract MockEIP2981 is IEIP2981, MockRoyalty, ERC165 {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 value) public override view returns (address, uint256) {
        if (_receivers[tokenId].length == 0) return (address(0), 0);
        return (_receivers[tokenId][0], _bps[tokenId][0]*value/10000);
    }
}