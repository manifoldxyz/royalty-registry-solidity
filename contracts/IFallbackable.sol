// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFallbackable {
    /**
     * @notice Set the address for fallback royalty look up
     * @dev This should be a permissioned function
     * @param fallbackRoyaltyLookup Address of the fallback look up contract
     */
    function setFallbackRoyaltyLookup(address fallbackRoyaltyLookup) external;
}
