// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Nifty legacy registry
 */
interface INiftyLegacyRegistry {
    /**
     * @dev Get royalites of a token
     * @return listBeneficiary adresses of royalty receivers 
     * @return listAmount amount to be paid to corresponding receiver
     */
    function royaltyInfo(address tokenAddress, uint256 tokenId, uint256 salePrice) external view returns(address payable[] memory, uint256[] memory);
}