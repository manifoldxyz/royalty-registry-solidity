// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { RoyaltyEngineV2 } from "../contracts/RoyaltyEngineV2.sol";
import { RoyaltySplitter } from "../contracts/overrides/RoyaltySplitter.sol";

import { IManifold } from "../contracts/specs/IManifold.sol";
import { IRaribleV2 } from "../contracts/specs/IRarible.sol";
import { IEIP2981 } from "../contracts/specs/IEIP2981.sol";
import { IRoyaltyEngineV1 } from "../contracts/IRoyaltyEngineV1.sol";
import { IRoyaltyRegistry } from "../contracts/IRoyaltyRegistry.sol";
import { IRoyaltySplitter, Recipient } from "../contracts/overrides/IRoyaltySplitter.sol";

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { GasGuzzlooooor } from "./helpers/engine/GasGuzzlooooor.sol";
import { OwnableStub } from "./helpers/OwnableStub.sol";

import { Manifold } from "./helpers/engine/Manifold.sol";
import { RaribleV2 } from "./helpers/engine/RaribleV2.sol";
import { EIP2981Impl } from "./helpers/engine/EIP2981.sol";

contract EngineV2Test is Test {
    int16 private constant NONE = -1;
    int16 private constant NOT_CONFIGURED = 0;
    int16 private constant MANIFOLD = 1;
    int16 private constant EIP2981 = 2;
    int16 private constant RARIBLEV2 = 3;
    int16 private constant ROYALTY_SPLITTER = 4;

    RoyaltyEngineV2 engine;
    OwnableStub ownable;

    function setUp() public {
        engine = new RoyaltyEngineV2();
        ownable = new OwnableStub();
    }

    function testSupportsInterface() public {
        assertTrue(engine.supportsInterface(type(IERC165).interfaceId)); // ERC165
        assertTrue(engine.supportsInterface(type(IRoyaltyEngineV1).interfaceId)); // RoyaltyEngineV1
    }

    function testInvalidateCachedRoyaltySpec() public {
        EIP2981Impl eip2981_1 = new EIP2981Impl(false);
        EIP2981Impl eip2981_2 = new EIP2981Impl(false);
        engine.getRoyalty(address(eip2981_1), 1, 1000);
        engine.getRoyalty(address(eip2981_2), 1, 1000);
        assertEq(engine.getCachedRoyaltySpec(address(eip2981_1)), EIP2981);
        assertEq(engine.getCachedRoyaltySpec(address(eip2981_2)), EIP2981);

        address[] memory tokens = new address[](2);
        tokens[0] = address(eip2981_1);
        tokens[1] = address(eip2981_2);
        engine.invalidateCachedRoyaltySpec(tokens);
        assertEq(engine.getCachedRoyaltySpec(address(eip2981_1)), NOT_CONFIGURED);
        assertEq(engine.getCachedRoyaltySpec(address(eip2981_2)), NOT_CONFIGURED);
    }

    function testGetRoyalty_empty() public {
        (address payable[] memory recipients, uint256[] memory amounts) = engine.getRoyalty(address(ownable), 1, 1000);
        assertEq(recipients.length, 0);
        assertEq(amounts.length, 0);
    }

    function testGetRoyalty_OOG() public {
        GasGuzzlooooor gasGuzzlooooor = new GasGuzzlooooor(address(this));
        vm.expectRevert("Invalid royalty amount");
        engine.getRoyalty(address(gasGuzzlooooor), 1, 1000);
    }

    function testGetRoyaltyView_OOG() public {
        GasGuzzlooooor gasGuzzlooooor = new GasGuzzlooooor(address(this));
        vm.expectRevert("Invalid royalty amount");
        engine.getRoyaltyView(address(gasGuzzlooooor), 1, 1000);
    }

    function testGetRoyaltyView_empty() public {
        (address payable[] memory recipients, uint256[] memory amounts) =
            engine.getRoyaltyView(address(ownable), 1, 1000);
        assertEq(recipients.length, 0);
        assertEq(amounts.length, 0);
    }

    function testRoyaltySplitter_multi() public {
        EIP2981Impl eip2981 = new EIP2981Impl(false);

        Recipient[] memory splits = new Recipient[](2);
        splits[0] = Recipient({ recipient: payable(address(this)), bps: 5000 });
        splits[1] = Recipient({ recipient: payable(address(1234)), bps: 5000 });

        RoyaltySplitter splitter = new RoyaltySplitter();
        splitter.initialize(splits);
        eip2981.setRoyaltyRecipient(address(splitter));

        (address payable[] memory recipients, uint256[] memory amounts) = engine.getRoyalty(address(eip2981), 1, 1000);
        assertEq(recipients.length, 2);
        assertEq(recipients[0], address(this));
        assertEq(recipients[1], address(1234));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 25);
        assertEq(amounts[1], 25);

        // do it again to make sure it's cached
        (recipients, amounts) = engine.getRoyalty(address(eip2981), 1, 1000);
        assertEq(recipients.length, 2);
        assertEq(recipients[0], address(this));
        assertEq(recipients[1], address(1234));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 25);
        assertEq(amounts[1], 25);

        assertEq(engine.getCachedRoyaltySpec(address(eip2981)), ROYALTY_SPLITTER);
    }

    function testGetRoyalty_Manifold() public {
        Manifold manifold = new Manifold(false);
        testSpecAndCache(false, address(manifold), MANIFOLD);
        manifold.setFail(true);
        testSpecAndCache(true, address(manifold), MANIFOLD);
        manifold = new Manifold(true);
        testSpecAndCache(true, address(manifold), MANIFOLD);
    }

    function testGetRoyalty_RaribleV2() public {
        RaribleV2 raribleV2 = new RaribleV2();
        testSpecAndCache(false, address(raribleV2), RARIBLEV2);
    }

    function testGetRoyalty_EIP2981() public {
        EIP2981Impl eip2981 = new EIP2981Impl(false);
        testSpecAndCache(false, address(eip2981), EIP2981);
        eip2981.setFail(true);
        testSpecAndCache(true, address(eip2981), EIP2981);
    }

    function testSpecAndCache(bool reverts, address tokenAddress, int16 assertSpec) internal {
        testSpecAndCache(reverts, tokenAddress, assertSpec, address(999));
    }

    function testSpecAndCache(bool reverts, address tokenAddress, int16 assertSpec, address recipient) internal {
        int16 startingSpec = engine.getCachedRoyaltySpec(tokenAddress);
        if (reverts) {
            vm.expectRevert("Invalid royalty amount");
        }
        (address payable[] memory recipients, uint256[] memory amounts) = engine.getRoyalty(tokenAddress, 1, 1000);

        if (!reverts) {
            assertEq(recipients.length, 1);
            assertEq(recipients[0], recipient);
            assertEq(amounts.length, 1);
            assertEq(amounts[0], 50);
        }

        if (reverts) {
            vm.expectRevert("Invalid royalty amount");
        }
        // do it again to make sure it's cached
        (recipients, amounts) = engine.getRoyalty(tokenAddress, 1, 1000);
        if (!reverts) {
            assertEq(recipients.length, 1);
            assertEq(recipients[0], recipient);
            assertEq(amounts.length, 1);
            assertEq(amounts[0], 50);
        }

        if (!reverts) {
            assertEq(engine.getCachedRoyaltySpec(tokenAddress), assertSpec);
        } else {
            assertEq(engine.getCachedRoyaltySpec(tokenAddress), startingSpec);
        }
    }
}
