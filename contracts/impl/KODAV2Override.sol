// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: knownorigin.io

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../specs/IKODAV2Override.sol";

/**
 * @dev Implementation of KODA V2 override
 * @notice KnownOrigin V2 (KODAV2) records expected commissions in simplistic single digit commission i.e. 100 = 10.0%, we dont store
 *         a primary vs secondary expected commission amount so we need work this out proportionally
 */
contract KODAV2Override is IKODAV2Override, ERC165, Ownable {

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IKODAV2Override).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice precision 100.00000%
    uint256 public modulo = 100_00000;

    /// @notice Secondary sale royalty fee
    uint256 public creatorRoyaltiesFee = 10_00000; // 10% by default

    function getKODAV2RoyaltyInfo(address _tokenAddress, uint256 _id, uint256 _amount)
    external
    override
    view
    returns (address payable[] memory receivers, uint256[] memory amounts) {

        // Get the edition the token is part of
        uint256 _editionNumber = IKODAV2(_tokenAddress).editionOfTokenId(_id);
        require(_editionNumber > 0, "Edition not found for token ID");

        // Get existing artist commission
        (address artistAccount, uint256 artistCommissionRate) = IKODAV2(_tokenAddress).artistCommission(_editionNumber);

        // work out the expected royalty payment
        uint256 totalRoyaltyToPay = (_amount / modulo) * creatorRoyaltiesFee;

        // Get optional commission set against the edition and work out the expected commission
        (uint256 optionalCommissionRate, address optionalCommissionRecipient) = IKODAV2(_tokenAddress).editionOptionalCommission(_editionNumber);
        if (optionalCommissionRate > 0) {

            receivers = new address payable[](2);
            amounts = new uint256[](2);

            uint256 totalCommission = artistCommissionRate + optionalCommissionRate;

            // Add the artist and commission
            receivers[0] = payable(artistAccount);
            amounts[0] = (totalRoyaltyToPay / totalCommission) * artistCommissionRate;

            // Add optional splits
            receivers[1] = payable(optionalCommissionRecipient);
            amounts[1] = (totalRoyaltyToPay / totalCommission) * optionalCommissionRate;
        } else {
            receivers = new address payable[](1);
            amounts = new uint256[](1);

            // Add the artist and commission
            receivers[0] = payable(artistAccount);
            amounts[0] = totalRoyaltyToPay;
        }

        return (receivers, amounts);
    }

    function updateCreatorRoyalties(uint256 _creatorRoyaltiesFee) external override onlyOwner {
        emit CreatorRoyaltiesFeeUpdated(creatorRoyaltiesFee, _creatorRoyaltiesFee);
        creatorRoyaltiesFee = _creatorRoyaltiesFee;
    }

}
