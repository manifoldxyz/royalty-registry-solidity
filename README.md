## Royalty Registry for any Marketplace

This is intended to be a royalty registry for any marketplace.

The hope is that:
- it becomes a de-facto way for marketplaces to lookup royalty information for any token.
- it is maintained by the community

## Overview

The royalty registry was designed with the following goals
- support backwards/legacy compatibility (by allowing all token contracts that didn't implement royalties to add an override)
  - an override only needs to support any one of the royalty standards defined in the registry.
- support a common interface for all prominent royalty standards (currently Rarible, Foundation, Manifold and EIP2981)

Following the feedback from a few of the larger marketplaces, the Royalty Registry will be split into two components.

### 1. Royalty Registry
This is the central contract to be used for determining what address should be used for royalty lookup given a token address.  The intent is to have one instance of this, supported by the community, with override capability for the larger platforms with many legacy contracts.  Override permissions should be expanded in the future for those that
do not implement Ownable or aren't platform controlled contracts.

Overrides are emitted as events so that any other systems that want to cache this data can do so.

#### Methods

```
function overrideAddress(address tokenAddress, address royaltyAddress) public
```
Override where to get royalty information from for a given token contract.  Only callable by the owner of the token contract (relies on @openzeppelin's Ownable implementation) or the owner of the Royalty Registry (i.e. DAO governance access control).  This allows legacy contracts to set royalties.

- Input parameter: *tokenAddress*   - address of token contract
- Input parameter: *royaltyAddress* - new contract location to lookup royalties

```
function getRoyaltyAddress(address tokenAddress) public view
```
Returns the address that should be used to lookup royalties.  Defaults to return the tokenAddress unless an override is set.

### 2. Royalty Engine (v1)

The common interface attempts to unify the lookup for various royalty specifications currently in existence.

As new standards are adopted, they can be added to the royalty engine.  If new standards require a more complex output, the royalty engine can be upgraded.

#### Methods

```
function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) public view override returns(address payable[] memory recipients, uint256[] memory amounts)
```
Get the royalties for a given token and sale amount

- Input parameter: *tokenAddress* - address of token
- Input parameter: *tokenId*      - id of token
- Input parameter: *value*        - sale value of token

Returns two arrays, first is the list of royalty recipients, second is the amounts for each recipient.

## Usage

An upgradeable version of both the Royalty Registry and Royalty Engine (v1) will be deployed for public consumption.  There should only be one instance of the Royalty Registry (in order to ensure that people who wish to override do not have to do so in multiple places), while many instances of the Royalty Engine can exist.

Marketplaces may choose to directly inherit the Royalty Engine to save a bit of gas (from our testing, a possible savings of 6400 gas per lookup).

### Web3 dApp
We intend to deploy a web3 dApp which will:
- allow a contract to configure their royalties or override their royalty location.
- return the royalty of any token using a user friendly UI

### Web2 Bridges
We intend to provide a web2 bridge for web2 applications (e.g. auction houses)