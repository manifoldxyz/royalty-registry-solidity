// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseOverrideTest } from "./BaseOverride.t.sol";
import { RoyaltyRegistry, IRoyaltyRegistry, IERC165 } from "../contracts/RoyaltyRegistry.sol";
import { AdminControlled } from "./helpers/AdminControlled.sol";
import { OwnableStub } from "./helpers/OwnableStub.sol";
import { AccessControlled } from "./helpers/AccessControlled.sol";
import { NiftyBuilderInstance } from "./helpers/NiftyBuilderInstance.sol";
import { ArtBlocks } from "./helpers/ArtBlocks.sol";
import { FoundationTreasuryNode } from "./helpers/FoundationTreasuryNode.sol";
import { Digitalax } from "./helpers/Digitalax.sol";

contract RegistryTest is BaseOverrideTest {
    function testInitialize() public {
        RoyaltyRegistry _registry = new RoyaltyRegistry(address(factory));
        _registry.initialize(address(this));
        assertEq(_registry.owner(), address(this));
        _registry = new RoyaltyRegistry(address(factory));
        _registry.initialize(address(1234));
        assertEq(_registry.owner(), address(1234));
    }

    function testConstructor() public {
        RoyaltyRegistry _registry = new RoyaltyRegistry(address(this));
        assertEq(_registry.OVERRIDE_FACTORY(), address(this));
        _registry = new RoyaltyRegistry(address(1234));
        assertEq(_registry.OVERRIDE_FACTORY(), address(1234));
    }

    function testOverrideAllowed_Ownable() public {
        address tokenAddress = address(ownable);
        ownable.transferOwnership(makeAddr("owner"));
        _testOverrideAllowed(makeAddr("owner"), tokenAddress);
    }

    function _testOverrideAllowed(address authedCaller, address tokenAddress) internal {
        vm.prank(registry.owner());
        assertTrue(registry.overrideAllowed(tokenAddress));
        vm.prank(authedCaller);
        assertTrue(registry.overrideAllowed(tokenAddress));
        vm.prank(makeAddr("not authed"));
        assertFalse(registry.overrideAllowed(tokenAddress));
    }

    function testOverrideAllowed_IAdmin() public {
        RoyaltyRegistry _registry = new RoyaltyRegistry(address(factory));
        _registry.initialize(address(this));
        AdminControlled owned = new AdminControlled(makeAddr('admin'));
        _testOverrideAllowed(makeAddr("admin"), address(owned));
    }

    function testOverideAllowed_IAccessControl() public {
        AccessControlled accessControlled = new AccessControlled(makeAddr("admin"));
        _testOverrideAllowed(makeAddr("admin"), address(accessControlled));
    }

    function testOverrideAllowed_NiftyBuilderInstance() public {
        // normal: should pass
        NiftyBuilderInstance niftyBuilder = new NiftyBuilderInstance(makeAddr('admin'));
        _testOverrideAllowed(makeAddr("admin"), address(niftyBuilder));

        niftyBuilder.setValidateSender(false);
        vm.prank(makeAddr("admin"));
        assertFalse(registry.overrideAllowed(address(niftyBuilder)));

        // bad registry: should fail
        niftyBuilder.setReturnBadRegistry(true);
        vm.startPrank(makeAddr("admin"));
        // doesn't fail gracefully
        vm.expectRevert();
        assertFalse(registry.overrideAllowed(address(niftyBuilder)));
        niftyBuilder.setReturnBadRegistry(false);
    }

    // test normal overrides for ArtBlocks, FoundationTreasuryNode, and Digitalax
    function testOverrideAllowed_ArtBlocks() public {
        ArtBlocks artBlocks = new ArtBlocks(makeAddr('admin'));
        _testOverrideAllowed(makeAddr("admin"), address(artBlocks));
    }

    function testOverrideAllowed_FoundationTreasuryNode() public {
        FoundationTreasuryNode foundationTreasuryNode = new FoundationTreasuryNode(makeAddr('admin'));
        _testOverrideAllowed(makeAddr("admin"), address(foundationTreasuryNode));
    }

    function testOverrideAllowed_Digitalax() public {
        Digitalax digitalax = new Digitalax(makeAddr('admin'));
        _testOverrideAllowed(makeAddr("admin"), address(digitalax));
    }

    function testGetRoyaltyLookupAddress() public {
        address tokenAddress = address(new OwnableStub());
        assertEq(registry.getRoyaltyLookupAddress(tokenAddress), tokenAddress);
        vm.etch(makeAddr("owner"), tokenAddress.code);
        registry.setRoyaltyLookupAddress(tokenAddress, makeAddr("owner"));
        assertEq(registry.getRoyaltyLookupAddress(tokenAddress), makeAddr("owner"));
    }

    function testSupportsInterface() public {
        assertTrue(registry.supportsInterface(type(IRoyaltyRegistry).interfaceId));
        assertTrue(registry.supportsInterface(type(IERC165).interfaceId));
    }

    function setRoyaltyLookupAddress_InvalidInput() public {
        vm.expectRevert("Invalid input");
        registry.setRoyaltyLookupAddress(address(1234), address(ownable));
        // opposite
        vm.expectRevert("Invalid input");
        registry.setRoyaltyLookupAddress(address(ownable), address(1234));
        // can bypass by setting to 0
        registry.setRoyaltyLookupAddress(address(ownable), address(0));
    }
}
