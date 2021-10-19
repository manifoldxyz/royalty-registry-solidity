// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./RoyaltyOverrideCloneable.sol";

/**
 * Clone Factory for EIP2981 reference override implementation
 */
contract EIP2981RoyaltyOverrideFactory {

  address public originAddress;

  event EIP2981RoyaltyOverrideCreated(address newEIP2981RoyaltyOverride);

  constructor(address origin) {
      originAddress = origin;
  }

  function createOverride() public returns (address) {
      address clone = Clones.clone(originAddress);
      EIP2981RoyaltyOverrideCloneable(clone).initialize();
      EIP2981RoyaltyOverrideCloneable(clone).transferOwnership(msg.sender);
      emit EIP2981RoyaltyOverrideCreated(clone);
      return clone;
  }
}