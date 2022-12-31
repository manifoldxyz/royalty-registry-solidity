// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
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
import { RoyaltyEngineV1 } from "../contracts/RoyaltyEngineV1.sol";
import { FallbackRegistry } from "../contracts/FallbackRegistry.sol";

contract BaseOverrideTest is Test {
    RoyaltyRegistry registry;
    EIP2981RoyaltyOverrideFactory factory;
    RoyaltySplitter splitter;
    EIP2981RoyaltyOverrideCloneable singleOverrideCloneable;
    EIP2981MultiReceiverRoyaltyOverrideCloneable multiOverrideCloneable;
    OwnableStub ownable;
    RoyaltyEngineV1 engine;
    FallbackRegistry fallbackRegistry;

    function setUp() public virtual {
        splitter = new RoyaltySplitter();
        singleOverrideCloneable = new EIP2981RoyaltyOverrideCloneable();
        singleOverrideCloneable.initialize(
            IEIP2981RoyaltyOverride.TokenRoyalty({bps: 500, recipient: address(this)}), address(this)
        );
        multiOverrideCloneable = new EIP2981MultiReceiverRoyaltyOverrideCloneable();
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient({recipient: payable(address(this)), bps: 5000});
        recipients[1] = Recipient({recipient: payable(address(1234)), bps: 5000});
        multiOverrideCloneable.initialize({
            royaltySplitterCloneable: payable(splitter),
            defaultBps: 500,
            defaultRecipients: recipients,
            initialOwner: address(this)
        });
        factory = new EIP2981RoyaltyOverrideFactory({
            singleOrigin: address(singleOverrideCloneable),
            multiOrigin: address(multiOverrideCloneable),
            royaltySplitterOrigin: payable(splitter)
        });
        registry = new RoyaltyRegistry(address(factory));
        registry.initialize(address(this));

        ownable = new OwnableStub();
        fallbackRegistry = new FallbackRegistry(address(this));
        engine = new RoyaltyEngineV1(address(fallbackRegistry));
        engine.initialize(address(this), address(registry));
    }

    function create2(bytes32 salt, bytes memory initCode) internal returns (address payable) {
        address payable addr;
        assembly {
            addr := create2(0, add(initCode, 32), mload(initCode), salt)
        }
        return addr;
    }
}
