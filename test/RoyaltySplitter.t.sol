// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseOverrideTest } from "./BaseOverride.t.sol";
import { IRoyaltySplitter } from "../contracts/overrides/IRoyaltySplitter.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Recipient } from "../contracts/overrides/RoyaltySplitter.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MintableERC20 is ERC20("", "") {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract RoyaltySplitterTest is BaseOverrideTest {
    function setUp() public override {
        super.setUp();
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient(payable(address(0x101)), 5000);
        recipients[1] = Recipient(payable(address(0x102)), 5000);
        splitter.initialize(recipients);
    }

    function testSupportsInterface() public {
        assertTrue(splitter.supportsInterface(type(IRoyaltySplitter).interfaceId));
        assertTrue(splitter.supportsInterface(type(IERC165).interfaceId));
    }

    function testSplitEth() public {
        (bool success,) = address(splitter).call{value: 1 ether}("");
        assertTrue(success);
        // call with 1 wei
        (success,) = address(splitter).call{value: 1}("");
        assertTrue(success);
        (success,) = address(splitter).call{value: 0}("");
        vm.deal(address(splitter), 0);
        (success,) = address(splitter).call{value: 0}("");
        assertTrue(success);
    }

    function testSplitEthPublic() public {
        vm.deal(address(splitter), 1 ether);
        splitter.splitETH();
    }

    function testSplitErc20() public {
        MintableERC20 token = new MintableERC20();
        token.mint(address(splitter), 1000);
        splitter.splitERC20Tokens(token);
        assertEq(token.balanceOf(address(0x101)), 500);
        assertEq(token.balanceOf(address(0x102)), 500);
    }

    function testProxyCall() public {
        vm.startPrank(address(0x101));
        vm.etch(address(0x111), "abcd");

        MintableERC20 token = new MintableERC20();
        token.mint(address(splitter), 1000);
        vm.expectCall(payable(address(0x111)), "");
        splitter.proxyCall(payable(address(0x111)), "");

        splitter.proxyCall(
            payable(address(token)), abi.encodeWithSelector(MintableERC20.mint.selector, address(0x101), 100)
        );
        assertEq(token.balanceOf(address(0x101)), 600);
        assertEq(token.balanceOf(address(0x102)), 500);

        vm.expectRevert("Split: ERC20 tokens must be split");
        splitter.proxyCall(payable(address(0x111)), abi.encodeWithSelector(ERC20.approve.selector, address(0), 100));
        vm.expectRevert("Split: ERC20 tokens must be split");
        splitter.proxyCall(
            payable(address(0x111)), abi.encodeWithSignature("increaseAllowance(address,uint256)", address(0), 100)
        );
    }

    function testOnlyRecipient() public {
        vm.startPrank(makeAddr("idk"));
        vm.expectRevert("Split: Can only be called by one of the recipients");
        vm.etch(address(0x111), "abcd");
        splitter.proxyCall(payable(address(0x111)), "");
    }

    function testProxyNonContract() public {
        vm.startPrank(address(0x101));
        vm.expectRevert("Address: call to non-contract");
        splitter.proxyCall(payable(address(0x101)), "");
    }
}
