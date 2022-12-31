// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseCreate2Script, console2 } from "create2-scripts/BaseCreate2Script.s.sol";
import { RoyaltyRegistry } from "../contracts/RoyaltyRegistry.sol";
import { RoyaltyEngineV1 } from "../contracts/RoyaltyEngineV1.sol";
import { createBytes32ImmutableSalt } from "create2-helpers/lib/ImmutableSalt.sol";
import { EIP2981MultiReceiverRoyaltyOverrideCloneable } from
    "../contracts/overrides/MultiReceiverRoyaltyOverrideCloneable.sol";
import { EIP2981RoyaltyOverrideCloneable } from "../contracts/overrides/RoyaltyOverrideCloneable.sol";
import { RoyaltySplitter } from "../contracts/overrides/RoyaltySplitter.sol";
import { EIP2981RoyaltyOverrideFactory } from "../contracts/overrides/RoyaltyOverrideFactory.sol";

contract DeployOverrideFactory is BaseCreate2Script {
    bytes32 REGISTRY_SALT;
    bytes32 ENGINE_SALT;

    function run() public {
        setUp();
        REGISTRY_SALT = createBytes32ImmutableSalt(address(0), uint96(bytes12("REGISTRY")));
        ENGINE_SALT == createBytes32ImmutableSalt(address(0), uint96(bytes12("ENGINE")));
        runOnNetworks(this.deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() external returns (address) {
        console2.log("Running TestDeployAndUpgrade with deployer", deployer);

        console2.log("Deploying OverrideFactory implementation");
        address overrideFactory = _deployOverrideFactory();
        console2.log("Deployed OverrideFactory at ", overrideFactory);
        return overrideFactory;
    }

    /**
     * @notice Deploy the Cloneable contracts used by the OverrideFactory, and the OverrideFactory itself.
     *         Differing implementations will result in different addresses for all contracts involved, but that's
     *         okay, since the address will still be deterministic: we can upgrade the RoyaltyRegistry to an
     *         implementation that stores the new Factory address as an immutable variable in its bytecode.
     */
    function _deployOverrideFactory() internal returns (address) {
        // cloneable single-recipient royalty override
        console2.log("Deploying single override");
        address singleOverride =
            _immutableCreate2IfNotDeployed(deployer, REGISTRY_SALT, type(EIP2981RoyaltyOverrideCloneable).creationCode);
        console2.log("Single override deployed to: ", singleOverride);
        console2.log("Deploying multi override");
        // cloneable multi-recipient royalty override
        address multiOverride = _immutableCreate2IfNotDeployed(
            deployer, REGISTRY_SALT, type(EIP2981MultiReceiverRoyaltyOverrideCloneable).creationCode
        );
        console2.log("Multi override deployed to: ", multiOverride);
        // cloneable royalty splitter contract
        console2.log("Deploying royalty splitter");
        address royaltySplit =
            _immutableCreate2IfNotDeployed(deployer, REGISTRY_SALT, type(RoyaltySplitter).creationCode);
        console2.log("Royalty splitter deployed to: ", royaltySplit);
        // encode constructor args for the OverrideFactory
        bytes memory factoryInitCode = abi.encodePacked(
            type(EIP2981RoyaltyOverrideFactory).creationCode, abi.encode(singleOverride, multiOverride, royaltySplit)
        );
        // deploy the OverrideFactory
        return _immutableCreate2IfNotDeployed(deployer, REGISTRY_SALT, factoryInitCode);
    }
}
