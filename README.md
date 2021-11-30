## Royalty Registry for any Marketplace

The Royalty Registry was developed in conjunction with Foundation, manifold.xyz, Nifty Gateway, OpenSea, Rariblee and SuperRare

The Royalty Registry is located at royaltyregistry.eth (0xad2184fb5dbcfc05d8f056542fb25b04fa32a95d) on the Ethereum mainnet.
Royalty Engine V1 is located at engine-v1.royaltyregistry.eth (0x8d17687ea9a6bb6efA24ec11DcFab01661b2ddcd) on the Ethereum mainnet.

https://royaltyregistry.xyz is a Web3 DApp which makes on-chain royalty lookups and override configurations easy.

The open-source code can be found at:
https://github.com/manifoldxyz/royalty-registry-client


## Overview

The royalty registry was designed with the following goals
- support backwards/legacy compatibility (by allowing all token contracts that didn't implement royalties to add an override)
  - an override only needs to support any one of the royalty standards defined in the registry.
- support a common interface for all prominent royalty standards (currently Rarible, Foundation, Manifold and EIP2981)

The Royalty Registry is comprised of two components.

### 1. Royalty Registry
This is the central contract to be used for determining what address should be used for royalty lookup given a token address.
The reason that this registry is necessary is to provide backwards compatability with contracts created prior to any on-chain royalty specs.
It provides the ability for these contracts to set up an on-chain royalty override with support for:
- @openzeppelin Ownable
- @openzepplin AccessControl (DEFAULT_ADMIN_ROLE)
- @manifoldxyz AdminControl https://github.com/manifoldxyz/libraries-solidity/tree/main/contracts/access

Override permissions can be expanded in the future by the community.

Overrides are emitted as events so that any other systems that want to cache this data can do so.

#### Methods

---

```
function setRoyaltyLookupAddress(address tokenAddress, address royaltyLookupAddress) public
```
Override where to get royalty information from for a given token contract.  Only callable by the owner of the token contract (relies on @openzeppelin's Ownable implementation) or the owner of the Royalty Registry (i.e. DAO governance access control).  This allows legacy contracts to set royalties.

- Input parameter: *tokenAddress*   - address of token contract
- Input parameter: *royaltyAddress* - new contract location to lookup royalties

---

```
function getRoyaltyLookupAddress(address tokenAddress) public view returns(address)
```
Returns the address that should be used to lookup royalties.  Defaults to return the tokenAddress unless an override is set.

---

```
function overrideAllowed(address tokenAddress) public view returns(bool)
```
Returns whether or not the address sender can override the royalty lookup address for the given token address.
Example Use Case: A royalty lookup dApp can also show override functionality if it detects that they can override

---

### 2. Royalty Engine (v1)

The royalty engine provides a common interface to unify the lookup for various royalty specifications currently in existence.

As new standards are adopted, they can be added to the royalty engine.  If new standards require a more complex output, the royalty engine can be upgraded.

The royalty engine also contains a spec cache to make lookups faster.  The cache is filled only if getRoyaltyAndCacheSpec is called, which is only useable within another contract as it is a mutable function.

#### Methods

---

```
function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) public override returns(address payable[] memory recipients, uint256[] memory amounts)
```
Get the royalties for a given token and sale amount.  Also cache the royalty spec for the given tokenAddress for more gas efficient future lookup.
Use this within marketplace contracts.

- Input parameter: *tokenAddress* - address of token
- Input parameter: *tokenId*      - id of token
- Input parameter: *value*        - sale value of token

Returns two arrays, first is the list of royalty recipients, second is the amounts for each recipient.

---

```
function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) public view override returns(address payable[] memory recipients, uint256[] memory amounts)
```
View only version of getRoyalty.  Useful for dApps that want to provide lookup functionality.

- Input parameter: *tokenAddress* - address of token
- Input parameter: *tokenId*      - id of token
- Input parameter: *value*        - sale value of token

Returns two arrays, first is the list of royalty recipients, second is the amounts for each recipient.

---

## Usage

An upgradeable version of both the Royalty Registry and Royalty Engine (v1) has been deployed for public consumption.  There should only be one instance of the Royalty Registry (in order to ensure that people who wish to override do not have to do so in multiple places), while many instances of the Royalty Engine can exist.

Marketplaces may choose to directly inherit the Royalty Engine to save a bit of gas (from our testing, a possible savings of 6400 gas per lookup).

To find the location of the Royalty Registry and Royalty Engine, please visit https://royaltyregistry.xyz, or reference the mainnnet locations above.

## Example Override Implementations

See ```contracts/overrides/RoyaltyOverride.sol``` for a reference override implementation.

See ```contracts/overrides/RoyaltyOverrideCore.sol``` if you would like to inherit EIP2981RoyaltyOverrideCore for your own smart contract.

See ```contracts/token/ERC721.sol``` and ```contracts/token/ERC1155.sol``` for reference ERC721 and ERC1155 reference implementations.

## Contributions

All contributions should come with accompanying test coverage.

### Installing Dependencies
`npm install`

### Running The Tests

Start development network (in separate terminal):

`npm run test:start-network`

Run tests:

`npm test`
