// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { RoyaltyRegistry } from "../contracts/RoyaltyRegistry.sol";

contract RoyaltyRegistryTest is RoyaltyRegistry {
    constructor(address overrideFactory) RoyaltyRegistry(overrideFactory) { }

    function msgSender() public view returns (address) {
        return _msgSender();
    }
}

contract MsgSenderOverrideTest is Test {
    RoyaltyRegistryTest test;

    function setUp() public virtual {
        test = new RoyaltyRegistryTest(makeAddr('override factory'));
        test.initialize(address(this));
    }

    function testMsgSenderOverride() public {
        // ensure msg.sender is returned as normal
        assertEq(test.msgSender(), address(this));
        // append the relayed caller to the calldata
        address relayedCaller = address(0x1234);
        bytes memory data = abi.encodeWithSelector(RoyaltyRegistryTest.msgSender.selector, relayedCaller);
        // prank as the override factory
        vm.prank(test.OVERRIDE_FACTORY());
        (, bytes memory returndata) = address(test).call(data);
        // ensure the relayed caller is returned
        assertEq(abi.decode(returndata, (address)), relayedCaller);
    }

    function testMsgSenderOverride(address notFactory, address relayedCaller) public {
        // reject fuzz if notFactory is the override factory
        vm.assume(notFactory != test.OVERRIDE_FACTORY());
        // append the relayed caller to the data
        bytes memory data = abi.encodeWithSelector(RoyaltyRegistryTest.msgSender.selector, relayedCaller);
        // call from an address that is not the override factory
        vm.prank(notFactory);
        (, bytes memory returndata) = address(test).call(data);
        // ensure msg.sender is returned as normal
        assertEq(abi.decode(returndata, (address)), notFactory);

        // prank as the override factory
        vm.prank(test.OVERRIDE_FACTORY());
        // call with modified calldata
        (, returndata) = address(test).call(data);
        // ensure the relayed caller is returned
        assertEq(abi.decode(returndata, (address)), relayedCaller);
    }
}
