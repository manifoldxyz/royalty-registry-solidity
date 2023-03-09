// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IRaribleV1 } from "../../../contracts/specs/IRarible.sol";

contract RaribleV1 is IRaribleV1 {
    address immutable creator;
    bool fail;

    constructor(bool _fail) {
        creator = msg.sender;
        fail = _fail;
    }

    function setFail(bool _fail) external {
        fail = _fail;
    }

    function getFeeBps(uint256) external view returns (uint256[] memory) {
        uint256[] memory bps = new uint256[](fail ? 2 : 1);
        bps[0] = 500;
        return bps;
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory) {
        address payable[] memory recipients = new address payable[](1);
        recipients[0] = payable(address(999));
        return recipients;
    }
}
