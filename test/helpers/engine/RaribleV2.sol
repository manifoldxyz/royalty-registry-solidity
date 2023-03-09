// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IRaribleV2 } from "../../../contracts/specs/IRarible.sol";

contract RaribleV2 is IRaribleV2 {
    address immutable creator;

    constructor() {
        creator = msg.sender;
    }

    function getRaribleV2Royalties(uint256) external view returns (Part[] memory) {
        Part[] memory parts = new Part[](1);
        parts[0] = Part(payable(address(999)), 500);
        return parts;
    }
}
