// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseCreate2Script, console2 } from "create2-scripts/BaseCreate2Script.s.sol";
import { FallbackRegistry } from "../contracts/FallbackRegistry.sol";

contract DeployFallbackRegistry is BaseCreate2Script {
    ///@dev OpenSea 5/7 multisig
    address INITIAL_FALLBACK_REGISTRY_OWNER = address(0xC669B5F25F03be2ac0323037CB57f49eB543657a);

    function run() public {
        runOnNetworks(this.deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() external returns (address) {
        console2.log("Running TestDeployAndUpgrade with deployer", deployer);

        console2.log("Deploying FallbackRegistry implementation");
        address fallbackRegistry = _deployFallbackRegistry();
        console2.log("Deployed FallbackRegistry at ", fallbackRegistry);
        require(
            FallbackRegistry(fallbackRegistry).owner() == INITIAL_FALLBACK_REGISTRY_OWNER, "Initial owner not correct"
        );
        return fallbackRegistry;
    }

    function _deployFallbackRegistry() internal returns (address) {
        bytes memory initCode =
            abi.encodePacked(type(FallbackRegistry).creationCode, abi.encode(INITIAL_FALLBACK_REGISTRY_OWNER));
        return _immutableCreate2IfNotDeployed({salt: bytes32(0), broadcaster: deployer, initCode: initCode});
    }
}
