// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseOverrideTest } from "./BaseOverride.t.sol";
import { IEIP2981MultiReceiverRoyaltyOverride } from "../contracts/overrides/IMultiReceiverRoyaltyOverride.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Recipient } from "../contracts/overrides/IRoyaltySplitter.sol";
import { EIP2981MultiReceiverRoyaltyOverrideCloneable } from
    "../contracts/overrides/MultiReceiverRoyaltyOverrideCloneable.sol";

contract MultiOverrideTest is BaseOverrideTest {
    address constant FIRST_CLONE = 0xCB6f5076b5bbae81D7643BfBf57897E8E3FB1db9;
    address constant SECOND_CLONE = 0x4f81992FCe2E1846dD528eC0102e6eE1f61ed3e2;

    function testSupportsInterface() public view {
        // multiCloneable.
        multiOverrideCloneable.supportsInterface(type(IEIP2981MultiReceiverRoyaltyOverride).interfaceId);
        multiOverrideCloneable.supportsInterface(type(IERC2981).interfaceId);
        multiOverrideCloneable.supportsInterface(type(IERC165).interfaceId);
    }

    function testSetTokenRoyalties() public {
        Recipient[] memory recipients = new Recipient[](1);

        recipients[0] = Recipient({recipient: payable(address(1234)), bps: 10000});
        IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[] memory configs =
            new IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig({
            tokenId: 1,
            royaltyBPS: 555,
            recipients: recipients
        });

        multiOverrideCloneable.setTokenRoyalties(configs);
        IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[] memory tokenRoyalties =
            multiOverrideCloneable.getTokenRoyalties();
        // validate length
        assertEq(tokenRoyalties.length, 1);

        // validate token id
        assertEq(tokenRoyalties[0].tokenId, 1);
        // validate bps
        assertEq(tokenRoyalties[0].royaltyBPS, 555);
        // validate recipients
        assertEq(tokenRoyalties[0].recipients.length, 1);
        assertEq(tokenRoyalties[0].recipients[0].recipient, address(1234));

        // now do the same but with multiple recipieints, bps totalling 10_000

        recipients = new Recipient[](2);
        recipients[0] = Recipient({recipient: payable(address(1234)), bps: 5000});
        recipients[1] = Recipient({recipient: payable(address(5678)), bps: 5000});
        configs = new IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig({
            tokenId: 2,
            royaltyBPS: 555,
            recipients: recipients
        });

        multiOverrideCloneable.setTokenRoyalties(configs);
        tokenRoyalties = multiOverrideCloneable.getTokenRoyalties();
        // validate length
        assertEq(tokenRoyalties.length, 2);
        // validate token id
        assertEq(tokenRoyalties[1].tokenId, 2);
        // validate bps
        assertEq(tokenRoyalties[1].royaltyBPS, 555);
        // validate recipients
        assertEq(tokenRoyalties[1].recipients.length, 2);
        assertEq(tokenRoyalties[1].recipients[0].recipient, address(1234));
        assertEq(tokenRoyalties[1].recipients[1].recipient, address(5678));
    }

    function testSetTokenRoyalties_invalidBps() public {
        Recipient[] memory recipients = new Recipient[](1);

        recipients[0] = Recipient({recipient: payable(address(1234)), bps: 10000});
        IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[] memory configs =
            new IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig({
            tokenId: 1,
            royaltyBPS: 10001,
            recipients: recipients
        });

        vm.expectRevert("Invalid bps");
        multiOverrideCloneable.setTokenRoyalties(configs);
    }

    function testSetTokenRoyalties_noRecipients() public {
        // first set a normal override for token id 1
        Recipient[] memory recipients = new Recipient[](1);
        recipients[0] = Recipient({recipient: payable(address(1234)), bps: 10000});

        IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[] memory configs =
            new IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig({
            tokenId: 1,
            royaltyBPS: 555,
            recipients: new Recipient[](0)
        });

        recipients = new Recipient[](0);

        configs = new IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig({
            tokenId: 1,
            royaltyBPS: 555,
            recipients: recipients
        });

        multiOverrideCloneable.setTokenRoyalties(configs);
        configs = multiOverrideCloneable.getTokenRoyalties();
        assertEq(configs.length, 0);
    }

    function testSetTokenRoyaltiesUpdateSameTokenId() public {
        // first set a normal override for token id 1
        Recipient[] memory recipients = new Recipient[](1);
        recipients[0] = Recipient({recipient: payable(address(1234)), bps: 10000});

        IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[] memory configs =
            new IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig({
            tokenId: 1,
            royaltyBPS: 555,
            recipients: recipients
        });

        multiOverrideCloneable.setTokenRoyalties(configs);
        configs = multiOverrideCloneable.getTokenRoyalties();
        assertEq(configs.length, 1);
        assertEq(configs[0].tokenId, 1);
        assertEq(configs[0].royaltyBPS, 555);
        assertEq(configs[0].recipients.length, 1);
        assertEq(configs[0].recipients[0].recipient, address(1234));

        // now update the same token id
        recipients = new Recipient[](1);
        recipients[0] = Recipient({recipient: payable(address(5678)), bps: 10000});

        configs = new IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig({
            tokenId: 1,
            royaltyBPS: 777,
            recipients: recipients
        });

        multiOverrideCloneable.setTokenRoyalties(configs);
        configs = multiOverrideCloneable.getTokenRoyalties();
        assertEq(configs.length, 1);
        assertEq(configs[0].tokenId, 1);
        assertEq(configs[0].royaltyBPS, 777);
        assertEq(configs[0].recipients.length, 1);
        assertEq(configs[0].recipients[0].recipient, address(5678));

        // now remove recipients

        configs = new IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig({
            tokenId: 1,
            royaltyBPS: 777,
            recipients: new Recipient[](0)
        });
        // update
        multiOverrideCloneable.setTokenRoyalties(configs);
        configs = multiOverrideCloneable.getTokenRoyalties();
        assertEq(configs[0].recipients.length, 0);
    }

    function testSetTokenRoyaltiesInvalidRecipientTotalBps() public {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient({recipient: payable(address(1234)), bps: 5000});
        recipients[1] = Recipient({recipient: payable(address(5678)), bps: 5001});

        IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[] memory configs =
            new IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig({
            tokenId: 1,
            royaltyBPS: 555,
            recipients: recipients
        });

        vm.expectRevert("Total bps must be 10000");
        multiOverrideCloneable.setTokenRoyalties(configs);
    }

    function testSetDefaultRoyalty_invalidBps() public {
        Recipient[] memory recipients = new Recipient[](1);
        recipients[0] = Recipient({recipient: payable(address(1234)), bps: 10001});

        vm.expectRevert("Invalid bps");
        multiOverrideCloneable.setDefaultRoyalty(10001, recipients);
    }

    function testSetDefaultRoyalty_updateDefaultRoyalty() public {
        Recipient[] memory recipients = new Recipient[](1);
        recipients[0] = Recipient({recipient: payable(address(1234)), bps: 10000});

        multiOverrideCloneable.setDefaultRoyalty(555, recipients);
        (uint256 royaltyBPS, Recipient[] memory tokenRoyalties) = multiOverrideCloneable.getDefaultRoyalty();
        assertEq(royaltyBPS, 555);
        assertEq(tokenRoyalties.length, 1);
        assertEq(tokenRoyalties[0].recipient, address(1234));
        assertEq(tokenRoyalties[0].bps, 10000);

        // now update
        recipients = new Recipient[](1);
        recipients[0] = Recipient({recipient: payable(address(5678)), bps: 10000});

        multiOverrideCloneable.setDefaultRoyalty(555, recipients);
        (royaltyBPS, tokenRoyalties) = multiOverrideCloneable.getDefaultRoyalty();
        assertEq(royaltyBPS, 555);
        assertEq(tokenRoyalties.length, 1);
        assertEq(tokenRoyalties[0].recipient, address(5678));
        assertEq(tokenRoyalties[0].bps, 10000);
    }

    function testRoyaltyInfo_specificTokenConfig() public {
        Recipient[] memory recipients = new Recipient[](1);
        recipients[0] = Recipient({recipient: payable(address(1234)), bps: 10000});

        IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[] memory configs =
            new IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig({
            tokenId: 1,
            royaltyBPS: 555,
            recipients: recipients
        });

        multiOverrideCloneable.setTokenRoyalties(configs);

        (address recipient, uint256 value) = multiOverrideCloneable.royaltyInfo(1, 10000);
        assertEq(recipient, FIRST_CLONE);
        assertEq(value, 555);
    }

    function testRoyaltyInfo_noConfig() public {
        multiOverrideCloneable = new EIP2981MultiReceiverRoyaltyOverrideCloneable();

        multiOverrideCloneable.initialize({
            royaltySplitterCloneable: payable(splitter),
            defaultBps: 0,
            defaultRecipients: new Recipient[](0),
            initialOwner: address(this)
        });
        (address recipient, uint256 value) = multiOverrideCloneable.royaltyInfo(1, 10000);
        assertEq(recipient, address(0));
        assertEq(value, 0);
    }

    function freshMultiOverride() internal returns (EIP2981MultiReceiverRoyaltyOverrideCloneable fresh) {
        fresh = new EIP2981MultiReceiverRoyaltyOverrideCloneable();

        fresh.initialize({
            royaltySplitterCloneable: payable(splitter),
            defaultBps: 0,
            defaultRecipients: new Recipient[](0),
            initialOwner: address(this)
        });
    }

    function testGetAllSplits() public {
        // set default royalty
        Recipient[] memory recipients = new Recipient[](1);
        recipients[0] = Recipient({recipient: payable(address(1234)), bps: 10000});
        // set default royalty
        multiOverrideCloneable.setDefaultRoyalty(555, recipients);

        // set token specific config
        recipients = new Recipient[](1);
        recipients[0] = Recipient({recipient: payable(address(5678)), bps: 10000});
        IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[] memory configs =
            new IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig[](1);
        configs[0] = IEIP2981MultiReceiverRoyaltyOverride.TokenRoyaltyConfig({
            tokenId: 1,
            royaltyBPS: 777,
            recipients: recipients
        });
        multiOverrideCloneable.setTokenRoyalties(configs);

        address payable[] memory splits = multiOverrideCloneable.getAllSplits();
        // not sure why this order
        assertEq(splits.length, 2);
        assertEq(splits[0], SECOND_CLONE);
        assertEq(splits[1], FIRST_CLONE);
    }

    function testGetAllSplits_noDefault() public {
        // only unititialized will return 0 splits
        multiOverrideCloneable = new EIP2981MultiReceiverRoyaltyOverrideCloneable();

        address payable[] memory splits = multiOverrideCloneable.getAllSplits();
        assertEq(splits.length, 0);
    }
}
