// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IImmutableCreate2Factory {
    function findCreate2Address(bytes32 salt, bytes memory initCode)
        external
        view
        returns (address deploymentAddress);

    function findCreate2AddressViaHash(bytes32 salt, bytes32 initCodeHash)
        external
        view
        returns (address deploymentAddress);

    function hasBeenDeployed(address deploymentAddress) external view returns (bool);

    function safeCreate2(bytes32 salt, bytes memory initializationCode)
        external
        payable
        returns (address deploymentAddress);
}
