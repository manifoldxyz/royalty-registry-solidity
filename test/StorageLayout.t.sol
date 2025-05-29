// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

contract StorageLayoutTest is Test {
    string[] watchedContracts;
    string constant LATEST = "latest";
    string constant EXISTING = "existing";
    mapping(bool => mapping(string => mapping(string => uint256))) contractNameCounts;
    mapping(string => mapping(string => StorageLayout)) contractLatestLayoutLabelToStruct;

    struct StorageLayout {
        string _contract;
        string _type;
        uint256 astId;
        string label;
        uint256 offset;
        string slot;
    }

    struct LayoutFile {
        StorageLayout[] _storage;
    }

    function setUp() public virtual {
        while (true) {
            string memory contractName = vm.readLine("watched_contracts.txt");
            if (bytes(contractName).length == 0) {
                break;
            }
            watchedContracts.push(contractName);
        }
    }

    function testLayoutMismatch() public {
        for (uint256 i = 0; i < watchedContracts.length; i++) {
            testLayout(watchedContracts[i]);
        }
    }

    function testLayout(string memory file) internal {
        LayoutFile memory existingLayout = getLayoutFileStruct(file, false);
        LayoutFile memory latestLayout = getLayoutFileStruct(file, true);
        compare(existingLayout, latestLayout);
    }

    function testBadLayout() public {
        vm.expectRevert(abi.encodeWithSelector(Status.selector, bytes32(uint256(1))));
        this.badLayout();
    }

    error Status(bytes32);

    function badLayout() external {
        testLayout("bad");

        revert Status(vm.load(HEVM_ADDRESS, bytes32("failed")));
    }

    function getLayoutFileStruct(string memory file, bool latest) public view returns (LayoutFile memory) {
        string memory content;
        if (latest) {
            content = vm.readFile(string.concat("storage_layouts/", file, "_latest.json"));
        } else {
            content = vm.readFile(string.concat("storage_layouts/", file, ".json"));
        }
        bytes memory contentBytes = vm.parseJson(content);
        LayoutFile memory latestLayout = abi.decode(contentBytes, (LayoutFile));
        return latestLayout;
    }

    /**
     * @dev Store the StorageLayout structs for latest in a mapping so we can compare existing to latest layout
     */
    function process(LayoutFile memory layout) internal {
        StorageLayout[] memory storageLayouts = layout._storage;
        for (uint256 i = 0; i < storageLayouts.length; i++) {
            StorageLayout memory storageLayout = storageLayouts[i];
            string memory storageKey = getStorageKey(storageLayout, true);
            contractLatestLayoutLabelToStruct[storageLayout._contract][storageKey] = storageLayout;
        }
    }

    function getStorageKey(StorageLayout memory layout, bool latest) internal returns (string memory) {
        // get current counter value and store incremented value
        uint256 counter = contractNameCounts[latest][layout._contract][layout.label]++;
        return string.concat(layout._type, layout._contract, layout.label, vm.toString(counter));
    }

    /**
     * @dev Compare the StorageLayout slot and offset values for each label of the StorageLayout structs in the existing LayoutFile using the layouts mapping
     */
    function compare(LayoutFile memory existing, LayoutFile memory latest) public {
        process(latest);
        StorageLayout[] memory existingLayouts = existing._storage;
        for (uint256 i = 0; i < existingLayouts.length; i++) {
            StorageLayout memory existingLayout = existingLayouts[i];
            string memory storageKey = getStorageKey(existingLayout, false); //._contract, existingLayout.label);
            StorageLayout memory latestLayout = contractLatestLayoutLabelToStruct[existingLayout._contract][storageKey];

            assertEq(
                existingLayout.slot,
                latestLayout.slot,
                string.concat(
                    "Slot mismatch for ", existingLayout.label, ": ", existingLayout.slot, " != ", latestLayout.slot
                )
            );
            assertEq(
                existingLayout.offset,
                latestLayout.offset,
                string.concat(
                    "Offset mismatch for ",
                    existingLayout.label,
                    ": ",
                    vm.toString(existingLayout.offset),
                    " != ",
                    vm.toString(latestLayout.offset)
                )
            );
        }
    }
}
