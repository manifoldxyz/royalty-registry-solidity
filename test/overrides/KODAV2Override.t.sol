// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { KODAV2Override } from "../../contracts/impl/KODAV2Override.sol";
import { IKODAV2Override, IKODAV2 } from "../../contracts/specs/IKODAV2Override.sol";

contract KODAV2 is IKODAV2 {
    address immutable ARTIST;
    uint256 immutable COMMISSION;
    address immutable EDITION_RECIPIENT;
    uint256 immutable EDITION_RATE;

    constructor(address artist, uint256 commission, address editionRecipient, uint256 editionRate) {
        ARTIST = artist;
        COMMISSION = commission;
        EDITION_RECIPIENT = editionRecipient;
        EDITION_RATE = editionRate;
    }

    function editionOfTokenId(uint256 tokenId) external pure override returns (uint256) {
        return tokenId;
    }

    function artistCommission(uint256) external view override returns (address, uint256) {
        return (ARTIST, COMMISSION);
    }

    function editionOptionalCommission(uint256) external view override returns (uint256, address) {
        return (EDITION_RATE, EDITION_RECIPIENT);
    }
}

contract KODAV2OverrideTest is Test {
    KODAV2Override test;
    KODAV2 kodav2;

    address artist;
    uint256 commission;
    address editionRecipient;
    uint256 editionRate;

    function setUp() public {
        test = new KODAV2Override();
        artist = makeAddr("artist");
        commission = 2;
        editionRecipient = makeAddr("recipient");
        editionRate = 0;
        kodav2 = new KODAV2(artist, commission, editionRecipient, editionRate);
    }

    function testSupportsInterface() public {
        assertTrue(test.supportsInterface(type(IKODAV2Override).interfaceId));
    }

    function testGetRoyaltyInfo() public {
        (address payable[] memory recipient, uint256[] memory amounts) =
            test.getKODAV2RoyaltyInfo(address(kodav2), 1, 1 ether);
        assertEq(recipient.length, 1);
        assertEq(recipient[0], payable(artist));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 0.1 ether);
    }

    function testGetRoyaltyInfo_EditionRate() public {
        kodav2 = new KODAV2(artist, commission, editionRecipient, 3);
        (address payable[] memory recipient, uint256[] memory amounts) =
            test.getKODAV2RoyaltyInfo(address(kodav2), 1, 1 ether);
        assertEq(recipient.length, 2);
        assertEq(recipient[0], payable(artist));
        assertEq(recipient[1], payable(editionRecipient));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 0.04 ether);
        assertEq(amounts[1], 0.06 ether);
    }

    function testGetRoyaltyInfo_editionNotFound() public {
        vm.expectRevert("Edition not found for token ID");
        test.getKODAV2RoyaltyInfo(address(kodav2), 0, 1000);
    }

    function testUpdateCreatorRoyalties() public {
        test.updateCreatorRoyalties(5_00000);
        assertEq(test.creatorRoyaltiesFee(), 5_00000);
    }

    function testUpdateCreatorRoyalties_onlyOwner() public {
        vm.startPrank(makeAddr("prankster"));
        vm.expectRevert("Ownable: caller is not the owner");
        test.updateCreatorRoyalties(5_00000);

        // revert Address(makeAddr('operator filter registry'));

        address freebie = 0x5Ea0000000000000000000000000000000000000;
    }

    error Address(address);
}
