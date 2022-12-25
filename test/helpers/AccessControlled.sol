// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

contract AccessControlled is AccessControl {
    constructor(address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }
}
