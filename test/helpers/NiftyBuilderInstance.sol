// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { INiftyBuilderInstance, INiftyRegistry } from "../../contracts/specs/INiftyGateway.sol";

contract NiftyBuilderInstance is INiftyBuilderInstance, INiftyRegistry {
    bool returnBadRegistry = false;
    bool validateSender = true;
    address public admin;

    constructor(address _admin) {
        admin = _admin;
    }

    function changeAdmin(address newAdmin) external {
        admin = newAdmin;
    }

    function niftyRegistryContract() external view override returns (address) {
        if (returnBadRegistry) {
            return address(0);
        }
        return address(this);
    }

    function isValidNiftySender(address sender) external view override returns (bool) {
        if (!validateSender) {
            return false;
        }
        return sender == admin;
    }

    function setReturnBadRegistry(bool _returnBadRegistry) external {
        returnBadRegistry = _returnBadRegistry;
    }

    function setValidateSender(bool _validateSender) external {
        validateSender = _validateSender;
    }
}
