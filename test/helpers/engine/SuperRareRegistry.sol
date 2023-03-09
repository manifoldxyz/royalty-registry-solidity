// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ISuperRareRegistry } from "../../../contracts/specs/ISuperRare.sol";

contract SuperRareRegistry is ISuperRareRegistry {
    address immutable creator;

    constructor() {
        creator = msg.sender;
    }

    function getERC721TokenRoyaltyPercentage(address, uint256) public pure override returns (uint8) {
        return 5;
    }

    function calculateRoyaltyFee(address _contractAddress, uint256 _tokenId, uint256 _amount)
        external
        pure
        override
        returns (uint256)
    {
        return _amount * getERC721TokenRoyaltyPercentage(_contractAddress, _tokenId) / 100;
    }

    function tokenCreator(address, uint256) external view override returns (address payable) {
        return payable(address(999));
    }
}
