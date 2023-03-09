// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IKODAV2Override } from "../../../contracts/specs/IKODAV2Override.sol";

contract KODAV2Override is IKODAV2Override {
    address immutable creator;
    bool fail;

    constructor(bool _fail) {
        creator = msg.sender;
        fail = _fail;
    }

    function setFail(bool _fail) external {
        fail = _fail;
    }

    function getKODAV2RoyaltyInfo(address, uint256, uint256)
        external
        view
        returns (address payable[] memory, uint256[] memory)
    {
        address payable[] memory receivers = new address payable[](fail ? 2 : 1);
        uint256[] memory basisPoints = new uint256[](1);
        receivers[0] = payable(address(999));
        basisPoints[0] = 50;
        return (receivers, basisPoints);
    }

    function updateCreatorRoyalties(uint256) external pure {
        revert("not implemented");
    }
}
