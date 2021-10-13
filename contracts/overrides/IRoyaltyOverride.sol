// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Simple EIP2981 reference override implementation
 */
interface IEIP2981RoyaltyOverride is IERC165 {

    function setTokenRoyalty(uint256 tokenId, address recipient, uint16 bps) external;

    function setDefaultRoyalty(address recipient, uint16 bps) external;

}
