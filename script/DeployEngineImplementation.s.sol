// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseCreate2Script, console2 } from "create2-scripts/BaseCreate2Script.s.sol";
import { RoyaltyRegistry } from "../contracts/RoyaltyRegistry.sol";
import { RoyaltyEngineV1 } from "../contracts/RoyaltyEngineV1.sol";
import { DeployOverrideFactory } from "./DeployOverrideFactory.s.sol";
import { DeployFallbackRegistry } from "./DeployFallbackRegistry.s.sol";

contract DeployImplementations is BaseCreate2Script {
    address registryImplementation;
    address engineImplementation;

    function run() public {
        runOnNetworks(this.deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() external returns (address) {
        console2.log("Running DeployEngineImplementation with deployer ", deployer);

        address fallbackRegistry = (new DeployFallbackRegistry()).deploy();

        console2.log("Deploying Engine implementation");
        engineImplementation = _immutableCreate2IfNotDeployed({
            salt: bytes32(0),
            broadcaster: deployer,
            initCode: abi.encodePacked(type(RoyaltyEngineV1).creationCode, abi.encode(fallbackRegistry))
        });
        console2.log("Deployed Engine implementation at ", engineImplementation);
        return registryImplementation;
    }

    function getImplementations() external view returns (address, address) {
        return (registryImplementation, engineImplementation);
    }
}
