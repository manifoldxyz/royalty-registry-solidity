// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { EIP2981RoyaltyOverrideFactory } from "../contracts/overrides/RoyaltyOverrideFactory.sol";
import { EIP2981MultiReceiverRoyaltyOverrideCloneable } from
    "../contracts/overrides/MultiReceiverRoyaltyOverrideCloneable.sol";
import { EIP2981RoyaltyOverrideCloneable } from "../contracts/overrides/RoyaltyOverrideCloneable.sol";
import { IEIP2981RoyaltyOverride } from "../contracts/overrides/IRoyaltyOverride.sol";
import { Recipient } from "../contracts/overrides/IRoyaltySplitter.sol";
import { RoyaltySplitter } from "../contracts/overrides/RoyaltySplitter.sol";
import { IEIP2981MultiReceiverRoyaltyOverride } from "../contracts/overrides/IMultiReceiverRoyaltyOverride.sol";
import { RoyaltyRegistry } from "../contracts/RoyaltyRegistry.sol";

import { OwnableStub } from "./helpers/OwnableStub.sol";

contract OverrideFactoryTest is Test {
    EIP2981RoyaltyOverrideCloneable single = new EIP2981RoyaltyOverrideCloneable();
    EIP2981MultiReceiverRoyaltyOverrideCloneable multi = new EIP2981MultiReceiverRoyaltyOverrideCloneable();
    RoyaltySplitter splitter = new RoyaltySplitter();
    RoyaltyRegistry registry;
    EIP2981RoyaltyOverrideFactory factory;
    OwnableStub ownable;
    address overrideLookup;

    error Result(address);

    // factory deploys using CREATE, and state is rolled back after each test, so the lookup address is always the same

    function setUp() public virtual {
        factory = new EIP2981RoyaltyOverrideFactory(
                address(single),
                address(multi),
                payable(splitter)
            );
        registry = new RoyaltyRegistry(address(factory));
        ownable = new OwnableStub();

        try this.getOverrideLookupAddress() {
            revert("Expected revert");
        } catch (bytes memory reason) {
            address _lookup;
            // skip first word (bytes length) plus 4 bytes (error signature) to load address
            assembly {
                _lookup := mload(add(reason, 0x24))
            }
            overrideLookup = _lookup;
        }
    }

    // OverrideLookup addresses are deterministic but may change depending on factory address, wrap deploy in a
    // try/catch so we can get the address programmatically without deploying it, rather than hard-coding a value
    function getOverrideLookupAddress() external {
        address lookup = factory.createOverrideAndRegister(
            address(registry),
            address(ownable),
            IEIP2981RoyaltyOverride.TokenRoyalty({bps: 500, recipient: address(this)})
        );
        revert Result(lookup);
    }

    function testSingleOverride() public {
        // expect registry is called with extra calldata
        vm.expectCall(
            address(registry),
            abi.encodeWithSelector(
                RoyaltyRegistry.setRoyaltyLookupAddress.selector, address(ownable), overrideLookup, address(this)
            )
        );
        factory.createOverrideAndRegister(
            address(registry),
            address(ownable),
            IEIP2981RoyaltyOverride.TokenRoyalty({bps: 500, recipient: address(this)})
        );
        // ensure we can look up override
        address lookupAddress = registry.getRoyaltyLookupAddress(address(ownable));
        assertEq(lookupAddress, overrideLookup);
    }

    function testMultiOverride() public {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient({recipient: payable(address(this)), bps: 5000});
        recipients[1] = Recipient({recipient: payable(address(1234)), bps: 5000});
        // expect registry is called with extra calldata
        vm.expectCall(
            address(registry),
            abi.encodeWithSelector(
                RoyaltyRegistry.setRoyaltyLookupAddress.selector, address(ownable), overrideLookup, address(this)
            )
        );
        factory.createOverrideAndRegister(address(registry), address(ownable), 1000, recipients);
        address lookupAddress = registry.getRoyaltyLookupAddress(address(ownable));
        assertEq(lookupAddress, overrideLookup);
    }

    function testSingleOverride_notOwner() public {
        ownable.transferOwnership(makeAddr("new owner"));
        vm.expectRevert("Permission denied");
        factory.createOverrideAndRegister(
            address(registry),
            address(ownable),
            IEIP2981RoyaltyOverride.TokenRoyalty({bps: 500, recipient: address(this)})
        );
    }

    function testMultiOverride_notOwner() public {
        ownable.transferOwnership(makeAddr("new owner"));
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient({recipient: payable(address(this)), bps: 5000});
        recipients[1] = Recipient({recipient: payable(address(1234)), bps: 5000});
        vm.expectRevert("Permission denied");
        factory.createOverrideAndRegister(address(registry), address(ownable), 1000, recipients);
    }

    function testSingleOverride_EOA() public {
        vm.expectRevert(0x01c491d3);
        factory.createOverrideAndRegister(
            makeAddr("eoa"),
            address(ownable),
            IEIP2981RoyaltyOverride.TokenRoyalty({bps: 500, recipient: address(this)})
        );
    }

    function testReverseLookup() public {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient({recipient: payable(address(this)), bps: 5000});
        recipients[1] = Recipient({recipient: payable(address(1234)), bps: 5000});
        // expect registry is called with extra calldata
        vm.expectCall(
            address(registry),
            abi.encodeWithSelector(
                RoyaltyRegistry.setRoyaltyLookupAddress.selector, address(ownable), overrideLookup, address(this)
            )
        );
        factory.createOverrideAndRegister(address(registry), address(ownable), 1000, recipients);
        address lookupAddress = registry.getRoyaltyLookupAddress(address(ownable));
        assertEq(lookupAddress, overrideLookup);

        // make another override
        factory.createOverrideAndRegister(address(registry), address(ownable), 1000, recipients);
        address newLookupAddress = registry.getRoyaltyLookupAddress(address(ownable));
        assertFalse(newLookupAddress == lookupAddress);
    }
}
