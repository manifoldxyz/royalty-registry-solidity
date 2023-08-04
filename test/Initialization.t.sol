// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

interface ITimelockController {
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) external;

    function execute(
        address target,
        uint256 value,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt
    ) external;
}

interface IOwnable {
    function owner() external returns (address);
}

interface IRoyaltyRegistry is IOwnable {
    function OVERRIDE_FACTORY() external returns (address);
}

interface IRoyaltyEngine is IOwnable {
    function FALLBACK_REGISTRY() external returns (address);
}

contract InitializationTest is Test {
    
    address gnosisSafe = 0x520f09e18895ACd6A9E75dE01355b5691Bf3D92B;
    address timelockController = 0xe3A6CD067a1193b903143C36dA00557c9d95C41e;
    address proxyAdmin = 0x0779702742c1397700e452A0976EfEF18D874764;
    
    address royaltyOverrideFactory = 0x103247393F448203ed7Ff7515E262316812637B4;
    address royaltyFallbackRegistry = 0xB78fC2052717C7AE061a14dB1fB2038d5AC34D29;

    address royaltyRegistryImpl = 0xd389340d95c851655dD99c5781be1c5e39d30B31;
    address royaltyEngineImpl = 0xD388d812c1cE2CE7C46D797684BA912De65CD414;
    
    address royaltyRegistry = 0x3D1151dc590ebF5C04501a7d4E1f8921546774eA;
    address royaltyEngine = 0xEF770dFb6D5620977213f55f99bfd781D04BBE15;


    function setUp() public {
        vm.createSelectFork("https://mainnet.base.org");
    }

    modifier withGnosisSafe() {
        vm.startPrank(gnosisSafe);
        _;
        vm.stopPrank();
    }

    function testRoyaltyRegistryInit() public withGnosisSafe {
        _initRoyaltyRegistry();
        assertEq(IRoyaltyRegistry(royaltyRegistry).owner(), timelockController);
        assertEq(IRoyaltyRegistry(royaltyRegistry).OVERRIDE_FACTORY(), royaltyOverrideFactory);
    }

    function testRoyaltyEngineInit() public withGnosisSafe {
        _initRoyaltyEngine();
        assertEq(IRoyaltyEngine(royaltyEngine).owner(), timelockController);
        assertEq(IRoyaltyEngine(royaltyEngine).FALLBACK_REGISTRY(), royaltyFallbackRegistry);
    }

    function _initRoyaltyRegistry() private {
        bytes memory data = abi.encodeWithSignature(
            "upgradeAndCall(address,address,bytes)",
            royaltyRegistry,
            royaltyRegistryImpl,
            abi.encodeWithSignature("initialize(address)", timelockController)
        );
        _timelockSchedule(data);
        vm.warp(86400 + block.timestamp); // 1 day later
        _timelockExecute(data);
    }

    function _initRoyaltyEngine() private {
        _initRoyaltyRegistry(); // requires royalty registry init'd
        bytes memory data = abi.encodeWithSignature(
            "upgradeAndCall(address,address,bytes)",
            royaltyEngine,
            royaltyEngineImpl,
            abi.encodeWithSignature("initialize(address,address)", timelockController, royaltyRegistry)
        );
        _timelockSchedule(data);
        vm.warp(86400 + block.timestamp); // 1 day later
        _timelockExecute(data);
    }


    function _timelockSchedule(bytes memory data) private {
        ITimelockController(timelockController).schedule(
            proxyAdmin,
            0,
            data,
            bytes32(0),
            bytes32(0),
            86400
        );
    }

    function _timelockExecute(bytes memory data) private {
        ITimelockController(timelockController).execute(
            proxyAdmin,
            0,
            data,
            bytes32(0),
            bytes32(0)
        );
    }
}