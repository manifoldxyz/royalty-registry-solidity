// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseCreate2Script, console2 } from "create2-scripts/BaseCreate2Script.s.sol";
import { RoyaltyRegistry } from "../contracts/RoyaltyRegistry.sol";
import { DeployOverrideFactory } from "./DeployOverrideFactory.s.sol";

contract DeployImplementations is BaseCreate2Script {
    address registryImplementation;

    function run() public {
        runOnNetworks(this.deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() external returns (address) {
        console2.log("Running DeployRegistryImplementation with deployer ", deployer);

        address overrideFactory = (new DeployOverrideFactory()).deploy();

        console2.log("Deploying Registry implementation");
        registryImplementation = _immutableCreate2IfNotDeployed({
            salt: bytes32(0),
            broadcaster: deployer,
            initCode: abi.encodePacked(type(RoyaltyRegistry).creationCode, abi.encode(overrideFactory))
        });
        console2.log("Deployed Registry implementation at ", registryImplementation);
        return registryImplementation;
    }

}
