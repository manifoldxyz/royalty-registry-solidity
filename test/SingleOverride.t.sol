// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseOverrideTest } from "./BaseOverride.t.sol";
import { EIP2981RoyaltyOverrideCloneable } from "../contracts/overrides/RoyaltyOverrideCloneable.sol";
import { EIP2981MultiReceiverRoyaltyOverrideCloneable } from
    "../contracts/overrides/MultiReceiverRoyaltyOverrideCloneable.sol";
import { RoyaltySplitter } from "../contracts/overrides/RoyaltySplitter.sol";
import { EIP2981RoyaltyOverrideFactory } from "../contracts/overrides/RoyaltyOverrideFactory.sol";
import { RoyaltyRegistry } from "../contracts/RoyaltyRegistry.sol";
import { OwnableStub } from "./helpers/OwnableStub.sol";
import { IEIP2981RoyaltyOverride } from "../contracts/overrides/IRoyaltyOverride.sol";
import { Recipient } from "../contracts/overrides/IRoyaltySplitter.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract SingleOverrideTest is BaseOverrideTest {
    function testSetDefaultRoyalty() public {
        singleOverrideCloneable.setDefaultRoyalty(
            IEIP2981RoyaltyOverride.TokenRoyalty({bps: 750, recipient: address(this)})
        );

        (address recipient, uint256 bps) = singleOverrideCloneable.royaltyInfo(2, 10_000);
        assertEq(recipient, address(this));
        assertEq(bps, 750);
    }

    function testSetTokenRoyalties() public {
        IEIP2981RoyaltyOverride.TokenRoyaltyConfig[] memory configs =
            new IEIP2981RoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981RoyaltyOverride.TokenRoyaltyConfig({tokenId: 1, bps: 555, recipient: address(1234)});

        singleOverrideCloneable.setTokenRoyalties(configs);
        assertEq(singleOverrideCloneable.getTokenRoyaltiesCount(), 1);
        assertEq(singleOverrideCloneable.getTokenRoyaltyByIndex(0).bps, 555);
        assertEq(singleOverrideCloneable.getTokenRoyaltyByIndex(0).recipient, address(1234));
        assertEq(singleOverrideCloneable.getTokenRoyaltyByIndex(0).tokenId, 1);

        (address recipient, uint256 bps) = singleOverrideCloneable.royaltyInfo(1, 10_000);
        assertEq(recipient, address(1234));
        assertEq(bps, 555);
    }

    function testSingleOverride_onlyOwner() public {
        IEIP2981RoyaltyOverride.TokenRoyaltyConfig[] memory configs =
            new IEIP2981RoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981RoyaltyOverride.TokenRoyaltyConfig({tokenId: 1, bps: 555, recipient: address(1234)});

        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert("Ownable: caller is not the owner");
        singleOverrideCloneable.setTokenRoyalties(configs);
        vm.expectRevert("Ownable: caller is not the owner");
        singleOverrideCloneable.setDefaultRoyalty(
            IEIP2981RoyaltyOverride.TokenRoyalty({bps: 750, recipient: address(this)})
        );
    }

    function testSupportsInterface() public {
        assertTrue(singleOverrideCloneable.supportsInterface(type(IERC2981).interfaceId));
    }

    function testZeroRoyalty() public {
        singleOverrideCloneable.setDefaultRoyalty(IEIP2981RoyaltyOverride.TokenRoyalty({bps: 0, recipient: address(0)}));
        (address recipient, uint256 bps) = singleOverrideCloneable.royaltyInfo(1, 10_000);
        assertEq(recipient, address(0));
        assertEq(bps, 0);
    }

    function testSetDefaultRoyalty_invalidBps() public {
        vm.expectRevert("Invalid bps");
        singleOverrideCloneable.setDefaultRoyalty(
            IEIP2981RoyaltyOverride.TokenRoyalty({bps: 10001, recipient: address(0)})
        );
    }

    function testSetTokenRoyalties_InvalidBps() public {
        IEIP2981RoyaltyOverride.TokenRoyaltyConfig[] memory configs =
            new IEIP2981RoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981RoyaltyOverride.TokenRoyaltyConfig({tokenId: 1, bps: 10001, recipient: address(1234)});

        vm.expectRevert("Invalid bps");
        singleOverrideCloneable.setTokenRoyalties(configs);
    }

    function testSetTokenRoyalties_deleteConfig() public {
        IEIP2981RoyaltyOverride.TokenRoyaltyConfig[] memory configs =
            new IEIP2981RoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981RoyaltyOverride.TokenRoyaltyConfig({tokenId: 1, bps: 555, recipient: address(1234)});

        singleOverrideCloneable.setTokenRoyalties(configs);
        assertEq(singleOverrideCloneable.getTokenRoyaltiesCount(), 1);
        assertEq(singleOverrideCloneable.getTokenRoyaltyByIndex(0).bps, 555);
        assertEq(singleOverrideCloneable.getTokenRoyaltyByIndex(0).recipient, address(1234));
        assertEq(singleOverrideCloneable.getTokenRoyaltyByIndex(0).tokenId, 1);

        configs[0] = IEIP2981RoyaltyOverride.TokenRoyaltyConfig({tokenId: 1, bps: 0, recipient: address(0)});
        singleOverrideCloneable.setTokenRoyalties(configs);
        assertEq(singleOverrideCloneable.getTokenRoyaltiesCount(), 0);
    }
}
