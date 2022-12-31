// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract GasGuzzlooooor is Ownable, ERC2981 {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        while (true) { }
        return super.royaltyInfo(_tokenId, _salePrice);
    }
}
