// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: artblocks.io

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMultiContractRoyaltyOverride is IERC165 {
    function getRoyalties(address tokenAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps);
}
