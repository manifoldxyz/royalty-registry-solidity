// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract OwnableStub {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public {
        owner = newOwner;
    }
}
