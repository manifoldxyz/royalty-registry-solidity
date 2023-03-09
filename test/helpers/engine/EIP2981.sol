// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IEIP2981 } from "../../../contracts/specs/IEIP2981.sol";

contract EIP2981Impl is IEIP2981 {
    address immutable creator;
    bool fail;

    constructor(bool _fail) {
        creator = msg.sender;
        fail = _fail;
    }

    function setFail(bool _fail) external {
        fail = _fail;
    }

    function royaltyInfo(uint256, uint256 value) external view override returns (address, uint256) {
      require(!fail);
      return (address(999), value*500/10000);
    }
}
