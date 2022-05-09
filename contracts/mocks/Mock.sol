// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../specs/IManifold.sol";
import "../specs/IRarible.sol";
import "../specs/IFoundation.sol";
import "../specs/IEIP2981.sol";
import "../specs/INiftyGateway.sol";
import "../specs/IDigitalax.sol";
import "../specs/IArtBlocks.sol";
import "../specs/IArtBlocksOverride.sol";
import "../specs/IKODAV2Override.sol";
import "../IRoyaltyEngineV1.sol";

/**
 * Does not implement any interface
 */
contract MockContract is Ownable {
}

/**
 * Base template for royalty
 */
contract MockRoyalty is Ownable {
    mapping(uint256 => address payable[]) internal _receivers;
    mapping(uint256 => uint256[]) internal _bps;

    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata bps) public {
        require(receivers.length == bps.length);
        _receivers[tokenId] = receivers;
        _bps[tokenId] = bps;
    }
}

/**
 * Implements Manifold interface
 */
contract MockManifold is IManifold, MockRoyalty, ERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IManifold).interfaceId || super.supportsInterface(interfaceId);
    }

    function getRoyalties(uint256 tokenId) public override view returns (address payable[] memory, uint256[] memory) {
        return (_receivers[tokenId], _bps[tokenId]);
    }

}

/**
 * Implements Foundation interface
 */
contract MockFoundation is IFoundation, IFoundationTreasuryNode, MockRoyalty, ERC165 {

    address payable private _foundationTreasury;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IFoundation).interfaceId || super.supportsInterface(interfaceId);
    }

    function getFees(uint256 tokenId) public override view returns (address payable[] memory, uint256[] memory) {
        return (_receivers[tokenId], _bps[tokenId]);
    }

    function getFoundationTreasury() public override view returns(address payable) {
        return _foundationTreasury;
    }

    function setFoundationTreasury(address payable newTreasury) public {
        _foundationTreasury = newTreasury;
    }

}

contract MockFoundationTreasury is IFoundationTreasury {
    address private _admin;

    function setAdmin(address admin) public {
        _admin = admin;
    }

    function isAdmin(address account) public override view returns(bool) {
        return account == _admin;
    }
}

/**
 * Implements RaribleV1 interface
 */
contract MockRaribleV1 is IRaribleV1, MockRoyalty, ERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IRaribleV1).interfaceId || super.supportsInterface(interfaceId);
    }

    function getFeeBps(uint256 tokenId) public override view returns (uint[] memory) {
        return _bps[tokenId];
    }

    function getFeeRecipients(uint256 tokenId) public override view returns (address payable[] memory) {
        return _receivers[tokenId];
    }

}

/**
 * Implements RaribleV2 interface
 */
contract MockRaribleV2 is IRaribleV2, MockRoyalty, ERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IRaribleV2).interfaceId || super.supportsInterface(interfaceId);
    }

    function getRaribleV2Royalties(uint256 tokenId) public override view returns (IRaribleV2.Part[] memory royalties) {
        royalties = new IRaribleV2.Part[](_receivers[tokenId].length);
        for (uint i = 0; i < _receivers[tokenId].length; i++) {
            royalties[i] = Part(_receivers[tokenId][i], uint96(_bps[tokenId][i]));
        }
        return royalties;
    }

}

/**
 * Implements EIP2981 interface
 */
contract MockEIP2981 is IEIP2981, MockRoyalty, ERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 value) public override view returns (address, uint256) {
        if (_receivers[tokenId].length == 0) return (address(0), 0);
        return (_receivers[tokenId][0], _bps[tokenId][0]*value/10000);
    }
}

/**
 * Nifty Gateway Mocks
 */
contract MockNiftyBuilder is INiftyBuilderInstance {
    address private _builderAddress;

    constructor(address builderAddress) {
        _builderAddress = builderAddress;
    }

     function niftyRegistryContract() external view override returns (address) {
         return _builderAddress;
     }
}

contract MockNiftyRegistry is INiftyRegistry {
    address private _approvedAddress;

    constructor(address approvedAddress) {
        _approvedAddress = approvedAddress;
    }

    function isValidNiftySender(address sending_key) external view override returns (bool) {
        return sending_key == _approvedAddress;
    }
}

contract MockDigitalaxNFT is IDigitalax {
    address private externalAccessControls;
    function accessControls() external view override returns (address){
        return externalAccessControls;
    }

    constructor(address _accessControls) {
        externalAccessControls = _accessControls;
    }
}

/**
 * DigitalAx Mocks
 */
contract MockDigitalaxAccessControls is IDigitalaxAccessControls {
    address private _approvedAddress;

    constructor(address approvedAddress) {
        _approvedAddress = approvedAddress;
    }

    function hasAdminRole(address _account) external view override returns (bool){
        return _account == _approvedAddress;
    }
}

/**
 * Art Blocks Mocks
 */
 contract MockArtBlocks is IArtBlocks {
     address public override admin;

     constructor() {
         admin = msg.sender;
     }
 }

 contract MockArtBlocksOverride is IArtBlocksOverride {
     address payable payee = payable(address(0));
     address payable secondaryPayee;
     uint256 totalRoyaltyBps = 500;

     constructor() {
         secondaryPayee = payable(msg.sender);
     }

     function setRoyalties(uint256 _totalRoyaltyBps) public {
         totalRoyaltyBps = _totalRoyaltyBps;
     }

     function getRoyalties(address /*tokenAddress*/, uint256 /*tokenId*/)
        external
        view
        override
        returns (address payable[] memory recipients_, uint256[] memory bps) {
            recipients_ = new address payable[](3);
            bps = new uint256[](3);
            // arbitrary 80/20 royalty split for testing
            recipients_[0] = payee;
            recipients_[1] = secondaryPayee;
            bps[0] = totalRoyaltyBps*80/100;
            bps[1] = totalRoyaltyBps*20/100;
            // leave last slot as 0 bps
        }
 }


/**
 * Mock ERC1155PresetMinterPauser
 */
contract MockERC1155PresetMinterPauser is ERC1155PresetMinterPauser {

    constructor() ERC1155PresetMinterPauser("") {}

}

/**
 * Simulate payment
 */
contract MockRoyaltyPayer {
    function deposit() public payable {

    }

    function payout(address royaltyEngine, address tokenAddress, uint256 tokenId, uint256 saleAmount) public {
        address payable[] memory recipients;
        uint256[] memory amounts;
        (recipients, amounts) = IRoyaltyEngineV1(royaltyEngine).getRoyaltyView(tokenAddress, tokenId, saleAmount);
        for (uint i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
        }
    }
}


/// Mock KODA V2 based on real world configs for a dual split of edition ID 575500
/// KO V2 is old and only has a a primary sale fee concept, we can however determine the secondary sale royalty
/// In this mock we see two splits, one getting 84% of primary and another getting 1% of primary, from these
/// values you can extrapolate any future royalty values
contract MockKODAV2 is IKODAV2 {
    function editionOfTokenId(uint256 _tokenId) external override pure returns (uint256 _editionNumber) {
        // Allow for unknown edition ID logic checks
        if(_tokenId == 0) return 0;
        return 575501;
    }

    function artistCommission(uint256 /*_editionNumber*/) external override pure returns (address _artistAccount, uint256 _artistCommission) {
        return (0x3f8C962eb167aD2f80C72b5F933511CcDF0719D4, 84);
    }

    function editionOptionalCommission(uint256 /*_editionNumber*/) external override pure returns (uint256 _rate, address _recipient) {
        return (1, 0xEEedc9941fb405D1ea90E6FD37d482C361e89Acd);
    }
}

/// Mock override for testing the registry only
contract MockKODAV2Override is IKODAV2Override {

    address public admin;
    uint256 public creatorRoyaltiesFee = 10_00000;

    constructor() {
        admin = msg.sender;
    }

    function getKODAV2RoyaltyInfo(address /*tokenAddress*/, uint256 /*id*/, uint256 _amount)
    external
    override
    view
    returns (address payable[] memory receivers, uint256[] memory amounts) {
        // Simple 50/50 splt between two addresses for this mock
        receivers = new address payable[](2);
        amounts = new uint256[](2);
        receivers[0] = payable(admin);
        receivers[1] = payable(admin);
        amounts[0] = (_amount / creatorRoyaltiesFee) * 5;
        amounts[1] = (_amount / creatorRoyaltiesFee) * 5;
    }

    function updateCreatorRoyalties(uint256 _creatorRoyaltiesFee) external override {
        creatorRoyaltiesFee = _creatorRoyaltiesFee;
    }

}
