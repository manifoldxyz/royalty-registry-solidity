// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseCreate2Script, console2 } from "create2-scripts/BaseCreate2Script.s.sol";
import { DeploySafe } from "create2-scripts/DeploySafe.s.sol";
import { DeployTimelockController } from "create2-scripts/DeployTimelockController.s.sol";
import { DeployProxyAdmin } from "create2-scripts/DeployProxyAdmin.s.sol";
import { DeployTransparentUpgradeableProxy } from "create2-scripts/DeployTransparentUpgradeableProxy.s.sol";
import { createBytes32ImmutableSalt } from "create2-helpers/lib/ImmutableSalt.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { DeployImplementations } from "./DeployImplementations.s.sol";
import { RoyaltyRegistry } from "../contracts/RoyaltyRegistry.sol";
import { RoyaltyEngineV1 } from "../contracts/RoyaltyEngineV1.sol";
import { EIP2981MultiReceiverRoyaltyOverrideCloneable } from
    "../contracts/overrides/MultiReceiverRoyaltyOverrideCloneable.sol";
import { EIP2981RoyaltyOverrideCloneable } from "../contracts/overrides/RoyaltyOverrideCloneable.sol";
import { RoyaltySplitter } from "../contracts/overrides/RoyaltySplitter.sol";
import { EIP2981RoyaltyOverrideFactory } from "../contracts/overrides/RoyaltyOverrideFactory.sol";

contract TestDeployAndUpgrade is BaseCreate2Script {
    ///@dev As documented in TransparentUpgradeableProxy
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    ///@dev As documented in TransparentUpgradeableProxy
    bytes32 constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    ///@dev _initialzied and _initializing are both stored in slot 0 by both the registry and engine
    ///once initialized, this slot will be non-zero
    bytes32 constant INITIALIZED_SLOT = bytes32(0);
    bytes32 REGISTRY_SALT;
    bytes32 ENGINE_SALT;
    address owner;
    address admin;

    function run() public {
        setUp();
        bytes32 adminKey = vm.envBytes32("ADMIN_PRIVATE_KEY");
        admin = vm.rememberKey(uint256(adminKey));

        REGISTRY_SALT = createBytes32ImmutableSalt(address(0), uint96(bytes12("REGISTRY")));
        ENGINE_SALT == createBytes32ImmutableSalt(address(0), uint96(bytes12("ENGINE")));
        runOnNetworks(this.deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() public returns (address) {
        console2.log("Running TestDeployAndUpgrade with deployer", deployer);
        vm.setEnv("TRANSPARENT_PROXY_INITIAL_ADMIN", vm.toString(admin));
        address initialInstance = _create2MinimumViableContract(deployer);
        console2.log("Deploying Registry instance");
        address registryProxy = (new DeployTransparentUpgradeableProxy()).deployTransparentUpgradeableProxy({
            salt: REGISTRY_SALT,
            initialAdmin: admin,
            initialImplementation: initialInstance,
            initializationData: ""
        });
        console2.log("Deploying Engine instance");
        address engineProxy = (new DeployTransparentUpgradeableProxy()).deployTransparentUpgradeableProxy({
            salt: ENGINE_SALT,
            initialAdmin: admin,
            initialImplementation: initialInstance,
            initializationData: ""
        });
        DeployImplementations implementationDeployer = new DeployImplementations();
        implementationDeployer.deploy();
        (address registryImplementation, address engineImplementation) = implementationDeployer.getImplementations();
        _upgradeRoyaltyProxyToRoyaltyRegistry(registryProxy, registryImplementation);
        _upgradeEngineProxyToRoyaltyEngine(engineProxy, engineImplementation, registryProxy);
        return registryProxy;
    }

    /**
     * @notice Deploys the RoyaltyRegistry implementation contract, and upgrades the RoyaltyRegistry proxy to point to it.
     */

    function _upgradeRoyaltyProxyToRoyaltyRegistry(address registryProxy, address _registryImplementation) internal {
        address initialRegistryOwner = vm.envAddress("INITIAL_REGISTRY_OWNER");
        _upgradeProxyAndAssert(
            registryProxy, _registryImplementation, abi.encodeWithSignature("initialize(address)", initialRegistryOwner)
        );
    }

    /**
     * @notice Deploys the RoyaltyEngine implementation contract, and upgrades the RoyaltyEngine proxy to point to it.
     */
    function _upgradeEngineProxyToRoyaltyEngine(
        address engineProxy,
        address _engineImplementation,
        address registryProxy
    ) internal {
        address initialRegistryOwner = vm.envAddress("INITIAL_REGISTRY_OWNER");
        _upgradeProxyAndAssert(
            engineProxy,
            _engineImplementation,
            abi.encodeWithSignature("initialize(address,address)", initialRegistryOwner, registryProxy)
        );
    }

    /**
     * @notice Deploy an implementation contract and upgrade the proxy to point to it. Also initializes the proxy if it
     *         has not been initialized yet.
     */
    function _upgradeProxyAndAssert(address proxy, address implementation, bytes memory conditionalInitializeData)
        internal
    {
        address currentImplementation = _loadProxyImplementation(proxy);
        // only upgrade if the current implementation is not the one we want
        if (implementation != currentImplementation) {
            // check if contract has been initialized
            bool shouldInitialize = _loadProxyInitialized(proxy) == bytes32(0);
            bytes memory callData;
            address expectedOwner;
            if (shouldInitialize) {
                // if contract has not been initialized, initial owner is the expected owner
                expectedOwner = vm.envAddress("INITIAL_REGISTRY_OWNER");
                // if the contract has not been initialized, we need to call the initialize function
                callData = conditionalInitializeData;
            } else {
                // if contract has been initialized, it may have a new owner, so use current owner as expected owner
                expectedOwner = Ownable(address(proxy)).owner();
            }
            // the admin must upgrade the proxy
            vm.broadcast(admin);
            if (callData.length > 0) {
                TransparentUpgradeableProxy(payable(proxy)).upgradeToAndCall(implementation, callData);
            } else {
                TransparentUpgradeableProxy(payable(proxy)).upgradeTo(implementation);
            }
            // ensure that owner was set correctly or that upgrading did not change the owner
            require(Ownable(proxy).owner() == expectedOwner, "Owner was not correct after upgrading ");
        }
    }

    /**
     * @notice Loads the implementation address from the proxy's storage.
     */
    function _loadProxyImplementation(address proxy) internal view returns (address) {
        return address(uint160(uint256(vm.load(proxy, IMPLEMENTATION_SLOT))));
    }

    /**
     * @notice Loads the admin address from the proxy's storage.
     */
    function _loadProxyAdmin(address proxy) internal view returns (address) {
        return address(uint160(uint256(vm.load(proxy, ADMIN_SLOT))));
    }

    function _loadProxyInitialized(address proxy) internal view returns (bytes32) {
        return vm.load(proxy, INITIALIZED_SLOT);
    }
}
