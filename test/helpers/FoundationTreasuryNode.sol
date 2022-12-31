// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IFoundation, IFoundationTreasury, IFoundationTreasuryNode } from "../../contracts/specs/IFoundation.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract FoundationTreasuryNode is IFoundation, IFoundationTreasury, IFoundationTreasuryNode, Ownable {
    address payable[] recipients;
    uint256[] amounts;

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    function getFees(uint256 tokenId) external view override returns (address payable[] memory, uint256[] memory) {
        return (recipients, amounts);
    }

    function setFees(address payable[] memory _recipients, uint256[] memory _amounts) external onlyOwner {
        recipients = _recipients;
        amounts = _amounts;
    }

    function getFoundationTreasury() external view override returns (address payable) {
        return payable(address(this));
    }

    function isAdmin(address account) external view override returns (bool) {
        return account == owner();
    }
}
