// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseCreate2Script, console2 } from "create2-scripts/BaseCreate2Script.s.sol";
import { RoyaltyEngineV2 } from "../contracts/RoyaltyEngineV2.sol";

contract DeployEngineV2 is BaseCreate2Script {
    address engineImplementation;

    function run() public {
        runOnNetworks(this.deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() external returns (address) {
        console2.log("Running DeployEngineV2Implementation with deployer ", deployer);
        console2.log("Deploying Engine implementation");
        engineImplementation = _immutableCreate2IfNotDeployed({
            salt: bytes32(0),
            broadcaster: deployer,
            initCode: type(RoyaltyEngineV2).creationCode
        });
        console2.log("Deployed Engine implementation at ", engineImplementation);
        return engineImplementation;
    }
}
