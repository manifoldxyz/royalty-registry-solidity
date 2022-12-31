// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IArtBlocks } from "../../contracts/specs/IArtBlocks.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract ArtBlocks is IArtBlocks, Ownable {
    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    function admin() external view override returns (address) {
        return owner();
    }
}
