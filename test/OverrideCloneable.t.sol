// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

import { EIP2981MultiReceiverRoyaltyOverrideCloneable } from
    "../contracts/overrides/MultiReceiverRoyaltyOverrideCloneable.sol";
import { EIP2981RoyaltyOverrideCloneable } from "../contracts/overrides/RoyaltyOverrideCloneable.sol";
import { IEIP2981RoyaltyOverride } from "../contracts/overrides/IRoyaltyOverride.sol";
import { Recipient } from "../contracts/overrides/IRoyaltySplitter.sol";
import { RoyaltySplitter } from "../contracts/overrides/RoyaltySplitter.sol";
import { IEIP2981MultiReceiverRoyaltyOverride } from "../contracts/overrides/IMultiReceiverRoyaltyOverride.sol";

contract OverrideCloneableTest is Test {
    EIP2981RoyaltyOverrideCloneable single;
    EIP2981MultiReceiverRoyaltyOverrideCloneable multi;
    RoyaltySplitter splitter;

    function setUp() public virtual {
        splitter = new RoyaltySplitter();
    }

    function testSingleInitialize() public {
        single = new EIP2981RoyaltyOverrideCloneable();
        single.initialize(IEIP2981RoyaltyOverride.TokenRoyalty({recipient: address(this), bps: 1000}), address(this));
        assertEq(single.owner(), address(this));
        (address recipient, uint256 bps) = single.defaultRoyalty();
        assertEq(recipient, address(this));
        assertEq(bps, 1000);
    }

    function testSingleInitialize(address recipient, uint16 bps, address owner) public {
        bps = uint16(bound(bps, 0, 9999));
        single = new EIP2981RoyaltyOverrideCloneable();
        single.initialize(IEIP2981RoyaltyOverride.TokenRoyalty({recipient: recipient, bps: bps}), owner);
        assertEq(single.owner(), owner);
        (address _recipient, uint256 _bps) = single.defaultRoyalty();
        assertEq(_recipient, recipient);
        assertEq(_bps, bps);
    }

    function testMultiInitialize() public {
        multi = new EIP2981MultiReceiverRoyaltyOverrideCloneable();
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient({recipient: payable(address(this)), bps: 5000});
        recipients[1] = Recipient({recipient: payable(address(1234)), bps: 5000});
        multi.initialize({
            royaltySplitterCloneable: payable(address(splitter)),
            defaultBps: 1000,
            initialOwner: address(this),
            defaultRecipients: recipients
        });
        assertEq(multi.owner(), address(this));
        (uint16 bps, Recipient[] memory retrievedRecipients) = multi.getDefaultRoyalty();

        assertEq(bps, 1000);
        assertEq(keccak256(abi.encode(retrievedRecipients)), keccak256(abi.encode(recipients)));
    }

    function testMultiInitialize(uint16 defaultBps, uint8 numRecipients, address initialOwner) public {
        defaultBps = uint16(bound(defaultBps, 0, 9999));
        numRecipients = uint8(bound(numRecipients, 1, 255));
        multi = new EIP2981MultiReceiverRoyaltyOverrideCloneable();
        Recipient[] memory recipients = new Recipient[](numRecipients);
        address[] memory addresses = new address[](numRecipients);
        for (uint8 i = 0; i < numRecipients; i++) {
            addresses[i] = address(uint160(1000 + uint16(i)));
        }
        for (uint8 i = 0; i < numRecipients; i++) {
            recipients[i] = Recipient({recipient: payable(addresses[i]), bps: 10_000 / numRecipients});
        }
        uint256 rounding = 10_000 - ((10_000 / numRecipients) * numRecipients);
        recipients[0].bps += uint16(rounding);

        multi.initialize({
            royaltySplitterCloneable: payable(address(splitter)),
            defaultBps: defaultBps,
            initialOwner: initialOwner,
            defaultRecipients: recipients
        });
        assertEq(multi.owner(), initialOwner);
        (uint16 bps, Recipient[] memory retrievedRecipients) = multi.getDefaultRoyalty();
        assertEq(bps, defaultBps);
        assertEq(keccak256(abi.encode(retrievedRecipients)), keccak256(abi.encode(recipients)));
    }
}
