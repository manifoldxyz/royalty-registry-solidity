// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseOverrideTest } from "./BaseOverride.t.sol";
import { OwnableStub } from "./helpers/OwnableStub.sol";
import { IEIP2981RoyaltyOverride } from "../contracts/overrides/IRoyaltyOverride.sol";
import { EIP2981RoyaltyOverrideCloneable } from "../contracts/overrides/RoyaltyOverrideCloneable.sol";
import { EIP2981MultiReceiverRoyaltyOverrideCloneable } from
    "../contracts/overrides/MultiReceiverRoyaltyOverrideCloneable.sol";
import { IEIP2981MultiReceiverRoyaltyOverride } from
    "../contracts/overrides/IMultiReceiverRoyaltyOverride.sol";
import { RoyaltyRegistry } from "../contracts/RoyaltyRegistry.sol";
import { RoyaltyEngineV1 } from "../contracts/RoyaltyEngineV1.sol";

import { SuperRareContracts } from "../contracts/libraries/SuperRareContracts.sol";

import { IManifold } from "../contracts/specs/IManifold.sol";
import { IRaribleV1, IRaribleV2 } from "../contracts/specs/IRarible.sol";
import { IFoundation } from "../contracts/specs/IFoundation.sol";
import { ISuperRareRegistry } from "../contracts/specs/ISuperRare.sol";
import { IEIP2981 } from "../contracts/specs/IEIP2981.sol";
import { IZoraOverride } from "../contracts/specs/IZoraOverride.sol";
import { IArtBlocksOverride } from "../contracts/specs/IArtBlocksOverride.sol";
import { IKODAV2Override } from "../contracts/specs/IKODAV2Override.sol";
import { IRoyaltyEngineV1 } from "../contracts/IRoyaltyEngineV1.sol";
import { IRoyaltyRegistry } from "../contracts/IRoyaltyRegistry.sol";
import { IRoyaltySplitter, Recipient } from "../contracts/overrides/IRoyaltySplitter.sol";

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { GasGuzzlooooor } from "./helpers/engine/GasGuzzlooooor.sol";

import { SuperRareRegistry } from "./helpers/engine/SuperRareRegistry.sol";
import { Manifold } from "./helpers/engine/Manifold.sol";
import { RaribleV1 } from "./helpers/engine/RaribleV1.sol";
import { RaribleV2 } from "./helpers/engine/RaribleV2.sol";
import { Foundation } from "./helpers/engine/Foundation.sol";
import { EIP2981Impl } from "./helpers/engine/EIP2981.sol";
import { ZoraOverride } from "./helpers/engine/ZoraOverride.sol";
import { ArtBlocksOverride } from "./helpers/engine/ArtBlocksOverride.sol";
import { KODAV2Override } from "./helpers/engine/KODAV2Override.sol";

contract EngineTest is BaseOverrideTest {
    int16 private constant NONE = -1;
    int16 private constant NOT_CONFIGURED = 0;
    int16 private constant MANIFOLD = 1;
    int16 private constant RARIBLEV1 = 2;
    int16 private constant RARIBLEV2 = 3;
    int16 private constant FOUNDATION = 4;
    int16 private constant EIP2981 = 5;
    int16 private constant SUPERRARE = 6;
    int16 private constant ZORA = 7;
    int16 private constant ARTBLOCKS = 8;
    int16 private constant KNOWNORIGINV2 = 9;
    int16 private constant ROYALTY_SPLITTER = 10;
    int16 private constant FALLBACK = type(int16).max;

    function testInitialize() public {
        engine = new RoyaltyEngineV1(address(fallbackRegistry));
        engine.initialize(address(this), address(registry));
        assertEq(address(engine.royaltyRegistry()), address(registry));
        assertEq(engine.owner(), address(this));
    }

    function testInitialize_BadRegistry() public {
        engine = new RoyaltyEngineV1(address(fallbackRegistry));
        vm.expectRevert();
        engine.initialize(address(this), address(0));
    }

    function testSupportsInterface() public {
        assertTrue(engine.supportsInterface(type(IERC165).interfaceId)); // ERC165
        assertTrue(engine.supportsInterface(type(IRoyaltyEngineV1).interfaceId)); // RoyaltyEngineV1
    }

    function testInvalidateCachedRoyaltySpec() public {
        factory.createOverrideAndRegister(address(registry), address(ownable), 500, new Recipient[](0));
        engine.getRoyalty(address(ownable), 1, 1000);
        assertEq(engine.getCachedRoyaltySpec(address(ownable)), ROYALTY_SPLITTER);
        engine.invalidateCachedRoyaltySpec(address(ownable));
        assertEq(engine.getCachedRoyaltySpec(address(ownable)), 0);
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

    function testEIP2981() public {
        factory.createOverrideAndRegister(
            address(registry),
            address(ownable),
            IEIP2981RoyaltyOverride.TokenRoyalty({bps: 500, recipient: address(this)})
        );
        testSpecAndCache(false, address(ownable), EIP2981, address(this));
    }

    function testRoyaltySplitter_multi() public {
        Recipient[] memory splits = new Recipient[](2);
        splits[0] = Recipient({recipient: payable(address(this)), bps: 5000});
        splits[1] = Recipient({recipient: payable(address(1234)), bps: 5000});
        factory.createOverrideAndRegister(address(registry), address(ownable), 500, splits);

        (address payable[] memory recipients, uint256[] memory amounts) = engine.getRoyalty(address(ownable), 1, 1000);
        assertEq(recipients.length, 2);
        assertEq(recipients[0], address(this));
        assertEq(recipients[1], address(1234));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 25);
        assertEq(amounts[1], 25);

        // do it again to make sure it's cached
        (recipients, amounts) = engine.getRoyalty(address(ownable), 1, 1000);
        assertEq(recipients.length, 2);
        assertEq(recipients[0], address(this));
        assertEq(recipients[1], address(1234));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 25);
        assertEq(amounts[1], 25);

        assertEq(engine.getCachedRoyaltySpec(address(ownable)), ROYALTY_SPLITTER);
    }

    function testRoyaltySplitter_multi_with_token_override() public {
        Recipient[] memory splits = new Recipient[](2);
        splits[0] = Recipient({recipient: payable(address(this)), bps: 5000});
        splits[1] = Recipient({recipient: payable(address(1234)), bps: 5000});
        address clone = factory.createOverrideAndRegister(address(registry), address(ownable), 500, splits);
        IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[] memory configs = new IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[](1);
        Recipient[] memory tokenSplits = new Recipient[](1);
        tokenSplits[0] = Recipient({recipient: payable(address(5678)), bps: 10000});
        configs[0] = IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig({tokenId: 100, recipients: tokenSplits, royaltyBPS: 500});
        IEIP2981MultiReceiverRoyaltyOverride(clone).setTokenRoyalties(configs);

        (address payable[] memory recipients, uint256[] memory amounts) = engine.getRoyalty(address(ownable), 1, 1000);
        assertEq(recipients.length, 2);
        assertEq(recipients[0], address(this));
        assertEq(recipients[1], address(1234));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 25);
        assertEq(amounts[1], 25);

        // do it again to make sure it's cached
        (recipients, amounts) = engine.getRoyalty(address(ownable), 1, 1000);
        assertEq(recipients.length, 2);
        assertEq(recipients[0], address(this));
        assertEq(recipients[1], address(1234));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 25);
        assertEq(amounts[1], 25);

        assertEq(engine.getCachedRoyaltySpec(address(ownable)), ROYALTY_SPLITTER);

        // check token override
        (recipients, amounts) = engine.getRoyalty(address(ownable), 100, 1000);
        assertEq(recipients.length, 1);
        assertEq(recipients[0], address(5678));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 50);
    }

    function testGetRoyalty_SuperRareRegistry() public {
        SuperRareRegistry superRareRegistry = new SuperRareRegistry();
        vm.etch(SuperRareContracts.SUPERRARE_REGISTRY, address(superRareRegistry).code);
        vm.etch(SuperRareContracts.SUPERRARE_V1, address(ownable).code);
        //v2
        vm.etch(SuperRareContracts.SUPERRARE_V2, address(ownable).code);

        testSpecAndCache(false, address(SuperRareContracts.SUPERRARE_V1), SUPERRARE);
        testSpecAndCache(false, address(SuperRareContracts.SUPERRARE_V2), SUPERRARE);
    }

    function testGetRoyalty_Manifold() public {
        Manifold manifold = new Manifold(false);
        testSpecAndCache(false, address(manifold), MANIFOLD);
        manifold.setFail(true);
        testSpecAndCache(true, address(manifold), MANIFOLD);
        manifold = new Manifold(true);
        testSpecAndCache(true, address(manifold), MANIFOLD);
    }

    // test rarible v1 and 2
    function testGetRoyalty_RaribleV1() public {
        RaribleV1 raribleV1 = new RaribleV1(false);
        testSpecAndCache(false, address(raribleV1), RARIBLEV1);
        raribleV1.setFail(true);
        testSpecAndCache(true, address(raribleV1), RARIBLEV1);
        raribleV1 = new RaribleV1(true);
        testSpecAndCache(true, address(raribleV1), RARIBLEV1);
    }

    function testGetRoyalty_RaribleV2() public {
        RaribleV2 raribleV2 = new RaribleV2();
        testSpecAndCache(false, address(raribleV2), RARIBLEV2);
    }
    // do the same for foundation, eip2981, zora, art blocks, and kodav2 overrides

    function testGetRoyalty_Foundation() public {
        Foundation foundation = new Foundation(false);
        testSpecAndCache(false, address(foundation), FOUNDATION);
        foundation.setFail(true);
        testSpecAndCache(true, address(foundation), FOUNDATION);
        foundation = new Foundation(true);
        testSpecAndCache(true, address(foundation), FOUNDATION);
    }

    function testGetRoyalty_EIP2981() public {
        EIP2981Impl eip2981 = new EIP2981Impl(false);
        testSpecAndCache(false, address(eip2981), EIP2981);
        eip2981.setFail(true);
        testSpecAndCache(true, address(eip2981), EIP2981);
    }

    function testGetRoyalty_Zora() public {
        ZoraOverride zora = new ZoraOverride(false);
        testSpecAndCache(false, address(zora), ZORA);
        zora.setFail(true);
        testSpecAndCache(true, address(zora), ZORA);

        zora = new ZoraOverride(true);
        testSpecAndCache(true, address(zora), ZORA);
    }

    function testGetRoyalty_ArtBlocksOverride() public {
        ArtBlocksOverride artBlocks = new ArtBlocksOverride(false);
        testSpecAndCache(false, address(artBlocks), ARTBLOCKS);
        artBlocks.setFail(true);
        testSpecAndCache(true, address(artBlocks), ARTBLOCKS);

        artBlocks = new ArtBlocksOverride(true);
        testSpecAndCache(true, address(artBlocks), ARTBLOCKS);
    }

    function testGetRoyalty_KodaV2() public {
        KODAV2Override kodaV2 = new KODAV2Override(false);
        testSpecAndCache(false, address(kodaV2), KNOWNORIGINV2);
        kodaV2.setFail(true);
        testSpecAndCache(true, address(kodaV2), KNOWNORIGINV2);
        kodaV2 = new KODAV2Override(true);
        testSpecAndCache(true, address(kodaV2), KNOWNORIGINV2);
    }

    function testGetRoyalty_FallbackRegistry() public {
        Recipient[] memory splits = new Recipient[](1);
        splits[0] = Recipient(payable(address(this)), 500);
        fallbackRegistry.setFallback(address(ownable), splits);
        testSpecAndCache(false, address(ownable), FALLBACK, address(this));
        // set bps to > 10000 and make sure it reverts
        splits[0] = Recipient(payable(address(this)), 10001);
        fallbackRegistry.setFallback(address(ownable), splits);
        testSpecAndCache(true, address(ownable), FALLBACK, address(this));
        ownable = new OwnableStub();
        fallbackRegistry.setFallback(address(ownable), splits);
        testSpecAndCache(true, address(ownable), FALLBACK, address(this));
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
