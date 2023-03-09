// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IFoundation } from "../../../contracts/specs/IFoundation.sol";

contract Foundation is IFoundation {
    address immutable creator;
    bool fail;

    constructor(bool _fail) {
        creator = msg.sender;
        fail = _fail;
    }

    function setFail(bool _fail) external {
        fail = _fail;
    }

    function getFees(uint256) external view returns (address payable[] memory, uint256[] memory) {
        address payable[] memory receivers = new address payable[](fail ? 2 : 1);
        uint256[] memory basisPoints = new uint256[](1);
        receivers[0] = payable(address(999));
        basisPoints[0] = 500;
        return (receivers, basisPoints);
    }
}
