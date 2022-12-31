// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IAdminControl } from "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";
import { ERC165, IERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract AdminControlled is IAdminControl, ERC165 {
    address public admin;

    constructor(address _admin) {
        admin = _admin;
    }
    /**
     * @dev gets address of all admins
     */

    function getAdmins() external view returns (address[] memory) {
        address[] memory admins = new address[](1);
        admins[0] = admin;
        return admins;
    }

    /**
     * @dev add an admin.  Can only be called by contract owner.
     */
    function approveAdmin(address) external pure {
        revert("not implemented");
    }

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     */
    function revokeAdmin(address) external {
        revert("not implemented");
    }

    /**
     * @dev checks whether or not given address is an admin
     * Returns True if they are
     */
    function isAdmin(address _admin) external view returns (bool) {
        return _admin == admin;
    }

    function changeAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        admin = _admin;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdminControl).interfaceId || super.supportsInterface(interfaceId);
    }
}
