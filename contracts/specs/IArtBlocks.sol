// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Art Blocks nfts
 */
interface IArtBlocks {
   // document getter function of public variable
   function admin() external view returns (address);
}

interface IArtBlocksOverride {
   function getRoyalties(address tokenAddress, uint256 tokenId) external view returns(address payable[] memory, uint256[] memory);
}
