## Royalty Registry for any Marketplace

This is intended to be a royalty registry for any marketplace.

The hope is that:
- it becomes a de-facto way for marketplaces to lookup royalty information for any token.
- it is maintained by the community

## Overview

The royalty registry was designed with the following goals
- support a common interface for all prominent royalty standards (currently Rarible, Foundation, Manifold and EIP2981)
- support backwards/legacy compatibility (by allowing all token contracts that didn't implement royalties to add an override)
  - an override only needs to support any one of the royalty standards defined in the registry.

The common interface attempts to unify the various royalty specifications currently in existence.

As new standards are adopted, they can be added to the registry.  If new standards require a more complex output, the royalty registry can be upgraded.

Overrides are emitted as events so anyone can re-create the registry.

## Methods

```
function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) public view override returns(address payable[] memory recipients, uint256[] memory amounts)
```
Get the royalties for a given token and sale amount

- Input parameter: *tokenAddress* - address of token
- Input parameter: *tokenId*      - id of token
- Input parameter: *value*        - sale value of token

Returns two arrays, first is the list of royalty recipients, second is the amounts for each recipient.

```
function overrideAddress(address tokenAddress, address royaltyAddress) public override
```
Override where to get royalty information from for a given token contract.  Only callable by the owner of the token contract (relies on @openzeppelin's Ownable implementation) or the owner of the Royalty Registry (i.e. DAO governance access control).  This allows legacy contracts to set royalties.

- Input parameter: *tokenAddress*   - address of token contract
- Input parameter: *royaltyAddress* - new contract location to lookup royalties

