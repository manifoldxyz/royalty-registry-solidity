// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Royalty lookup
 * @notice This interface represent a type of contracts which allow royalty look up for a collection and a token id.
 */
interface IRoyaltyLookUp {
    /**
     * @notice This function retrieves the set of recipients and respective fees for a collection 
               and optionally a specific token therein
     * @dev Token Id can be ignored if royalty is set at the token collection level
     * @param tokenAddress Token for which to retrieve the royalty
     * @param tokenId Individual Token Id for which to retrieve the royalty. This is optional.
     * @return recipients List of recipients for the royalty. If empty, no royalty is set.
     * @return feeInBPS List of fees express in bps to send to the recipients at the same index
     */
    function getRoyalties(address tokenAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory recipients, uint256[] memory feeInBPS);
}
