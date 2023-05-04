// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseCreate2Script, console2 } from "create2-scripts/BaseCreate2Script.s.sol";
import { DeploySafe } from "create2-scripts/DeploySafe.s.sol";
import { DeployTimelockController } from "create2-scripts/DeployTimelockController.s.sol";
import { DeployProxyAdmin } from "create2-scripts/DeployProxyAdmin.s.sol";
import { DeployTransparentUpgradeableProxy } from "create2-scripts/DeployTransparentUpgradeableProxy.s.sol";
import { createBytes32ImmutableSalt } from "create2-helpers/lib/ImmutableSalt.sol";

contract DeployRegistryMultichain is BaseCreate2Script {
    bytes32 REGISTRY_SALT;
    bytes32 ENGINE_SALT;

    function run() public {
        setUp();
        REGISTRY_SALT = createBytes32ImmutableSalt(address(0), uint96(bytes12("REGISTRY")));
        // Original script used to deploy had a typo, which resulted in the SALT being set to zero.
        ENGINE_SALT = bytes32(0);
        runOnNetworks(this.deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() public returns (address) {
        address safe = (new DeploySafe()).deploy();
        vm.setEnv("TIMELOCK_PROPOSERS", vm.toString(safe));
        address timelock = (new DeployTimelockController()).deploy();
        vm.setEnv("INITIAL_PROXY_ADMIN_OWNER", vm.toString(timelock));
        address proxyAdmin = (new DeployProxyAdmin()).deploy();
        vm.setEnv("TRANSPARENT_PROXY_INITIAL_ADMIN", vm.toString(proxyAdmin));
        address initialInstance = _create2MinimumViableContract(deployer);
        console2.log("Deploying Registry instance");
        address registryProxy = (new DeployTransparentUpgradeableProxy()).deployTransparentUpgradeableProxy({
            salt: REGISTRY_SALT,
            initialAdmin: vm.envAddress("TRANSPARENT_PROXY_INITIAL_ADMIN"),
            initialImplementation: initialInstance,
            initializationData: ""
        });
        console2.log("Deploying Engine instance");
        address engineProxy = (new DeployTransparentUpgradeableProxy()).deployTransparentUpgradeableProxy({
            salt: ENGINE_SALT,
            initialAdmin: vm.envAddress("TRANSPARENT_PROXY_INITIAL_ADMIN"),
            initialImplementation: initialInstance,
            initializationData: ""
        });
        return registryProxy;
    }
}
