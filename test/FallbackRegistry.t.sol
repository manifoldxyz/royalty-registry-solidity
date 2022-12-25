// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseOverrideTest } from "./BaseOverride.t.sol";
import { Recipient } from "../contracts/overrides/IRoyaltySplitter.sol";
import { FallbackRegistry } from "../contracts/FallbackRegistry.sol";

contract FallbackRegistryTest is BaseOverrideTest {
    function testSetFallback() public {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient({recipient: payable(address(this)), bps: 123});
        recipients[1] = Recipient({recipient: payable(address(1234)), bps: 456});
        fallbackRegistry.setFallback(address(ownable), recipients);
        Recipient[] memory result = fallbackRegistry.getRecipients(address(ownable));
        assertEq(result.length, 2);
        assertEq(result[0].recipient, address(this));
        assertEq(result[0].bps, 123);
        assertEq(result[1].recipient, address(1234));
        assertEq(result[1].bps, 456);
    }

    function testSetFallback_overwriteLongerLength() public {
        testSetFallback();
        Recipient[] memory recipients2 = new Recipient[](3);
        recipients2[0] = Recipient({recipient: payable(address(this)), bps: 123});
        recipients2[1] = Recipient({recipient: payable(address(1234)), bps: 456});
        recipients2[2] = Recipient({recipient: payable(address(5678)), bps: 789});
        fallbackRegistry.setFallback(address(ownable), recipients2);
        Recipient[] memory result = fallbackRegistry.getRecipients(address(ownable));
        assertEq(result.length, 3);
        assertEq(result[0].recipient, address(this));
        assertEq(result[0].bps, 123);
        assertEq(result[1].recipient, address(1234));
        assertEq(result[1].bps, 456);
        assertEq(result[2].recipient, address(5678));
        assertEq(result[2].bps, 789);
    }

    function testSetFallback_overwriteShorterLength() public {
        testSetFallback();
        Recipient[] memory recipients2 = new Recipient[](1);
        recipients2[0] = Recipient({recipient: payable(address(this)), bps: 123});
        fallbackRegistry.setFallback(address(ownable), recipients2);
        Recipient[] memory result = fallbackRegistry.getRecipients(address(ownable));
        assertEq(result.length, 1);
        assertEq(result[0].recipient, address(this));
        assertEq(result[0].bps, 123);
    }

    function testSetFallback_zeroLength() public {
        testSetFallback();
        Recipient[] memory recipients2 = new Recipient[](0);
        fallbackRegistry.setFallback(address(ownable), recipients2);
        Recipient[] memory result = fallbackRegistry.getRecipients(address(ownable));
        assertEq(result.length, 0);
    }

    function testSetFallbacks() public {
        FallbackRegistry.TokenFallback[] memory bundle = new FallbackRegistry.TokenFallback[](2);
        bundle[0] = FallbackRegistry.TokenFallback({tokenAddress: address(ownable), recipients: new Recipient[](2)});
        bundle[0].recipients[0] = Recipient({recipient: payable(address(this)), bps: 123});
        bundle[0].recipients[1] = Recipient({recipient: payable(address(1234)), bps: 456});
        bundle[1] = FallbackRegistry.TokenFallback({tokenAddress: address(1234), recipients: new Recipient[](2)});
        bundle[1].recipients[0] = Recipient({recipient: payable(address(5678)), bps: 789});
        bundle[1].recipients[1] = Recipient({recipient: payable(address(9012)), bps: 345});
        fallbackRegistry.setFallbacks(bundle);
        Recipient[] memory result = fallbackRegistry.getRecipients(address(ownable));
        assertEq(result.length, 2);
        assertEq(result[0].recipient, address(this));
        assertEq(result[0].bps, 123);
        assertEq(result[1].recipient, address(1234));
        assertEq(result[1].bps, 456);
        result = fallbackRegistry.getRecipients(address(1234));
        assertEq(result.length, 2);
        assertEq(result[0].recipient, address(5678));
        assertEq(result[0].bps, 789);
        assertEq(result[1].recipient, address(9012));
        assertEq(result[1].bps, 345);
    }

    function testSetFallback_onlyOwner() public {
        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert("Ownable: caller is not the owner");
        fallbackRegistry.setFallback(address(ownable), new Recipient[](0));
    }

    function testSetFallbacks_onlyOwner() public {
        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert("Ownable: caller is not the owner");
        fallbackRegistry.setFallbacks(new FallbackRegistry.TokenFallback[](0));
    }
}
