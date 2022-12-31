// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IDigitalax, IDigitalaxAccessControls } from "../../contracts/specs/IDigitalax.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Digitalax is IDigitalax, IDigitalaxAccessControls, Ownable {
    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    function accessControls() external view override returns (address) {
        return address(this);
    }

    function hasAdminRole(address _account) external view override returns (bool) {
        return _account == owner();
    }
}
