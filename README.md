## Royalty Registry for any Marketplace

The Royalty Registry was developed in conjunction with Foundation, manifold.xyz, Nifty Gateway, OpenSea, Rarible, SuperRare and Zora.

Please visit https://royaltyregistry.xyz for Registry and Engine deployment locations for each network.

https://royaltyregistry.xyz is a Web3 DApp which makes on-chain royalty lookups and override configurations easy.

The open-source code can be found at:
https://github.com/manifoldxyz/royalty-registry-client

## Deployments

Ethereum and Polygon were deployed using a legacy method without CREATE2 and hence the proxies live at different addresses. For all other EVM chains, all the contracts live at the same address.

Note: Future implementations, the override factory, and fallback registry will be the same on all chains, including Ethereum and Polygon.

Currently supported chains:
-  Ethereum
-  Polygon
-  Optimism
-  Arbitrum
-  Avalanche
-  Binance

### All EVM Chains

<table>
  <tr>
    <td>TimeLock Controller</td>
    <td>0xe3A6CD067a1193b903143C36dA00557c9d95C41e</td>
  </tr>
  <tr>
    <td>Royalty Registry Impl</td>
    <td>0xd389340d95c851655dD99c5781be1c5e39d30B31</td>
  </tr>
  <tr>
    <td>Royalty Engine Impl</td>
    <td>0xD388d812c1cE2CE7C46D797684BA912De65CD414</td>
  </tr>
  <tr>
    <td>Royalty Override Factory</td>
    <td >0x103247393F448203ed7Ff7515E262316812637B4</td>
  </tr>
  <tr>
    <td>Royalty Fallback Registry</td>
    <td>0xB78fC2052717C7AE061a14dB1fB2038d5AC34D29</td>
  </tr>
</table>

### Ethereum & Polygon

<table>
  <tr>
    <td></td>
    <td>Ethereum</td>
    <td>Polygon</td>
  </tr>
  <tr>
    <td>Gnosis Safe</td>
    <td>0xA70e7Ef659C209D977f0f5Ab932F3f775a94502F</td>
    <td>0xdAC451C0b1c13d7aF7f38022e6A2A29211Cc80d5</td>
  </tr>
  <tr>
    <td>Proxy Admin</td>
    <td>0xc9198CbbB57708CF31e0caBCe963c98e60d333c3</td>
    <td>0x40d603b2e9B3dE39ddc28Fb93a46BbB8E82b8a88</td>
  </tr>
  <tr>
    <td>Royalty Registry</td>
    <td>0xaD2184FB5DBcfC05d8f056542fB25b04fa32A95D</td>
    <td>0xe7c9Cb6D966f76f3B5142167088927Bf34966a1f</td>
  </tr>
  <tr>
    <td>Royalty Engine</td>
    <td>0x0385603ab55642cb4Dd5De3aE9e306809991804f</td>
    <td>0x28EdFcF0Be7E86b07493466e7631a213bDe8eEF2</td>
  </tr>
</table>


### Other EVM Chains

<table>
  <tr>
    <td>Gnosis Safe</td>
    <td>0x520f09e18895ACd6A9E75dE01355b5691Bf3D92B</td>
  </tr>
  <tr>
    <td>TimeLock Controller</td>
    <td>0xe3A6CD067a1193b903143C36dA00557c9d95C41e</td>
  </tr>
  <tr>
    <td>Proxy Admin</td>
    <td>0x0779702742c1397700e452A0976EfEF18D874764</td>
  </tr>
  <tr>
    <td>Royalty Registry</td>
    <td>0x3D1151dc590ebF5C04501a7d4E1f8921546774eA</td>
  </tr>
  <tr>
    <td>Royalty Engine</td>
    <td>0xEF770dFb6D5620977213f55f99bfd781D04BBE15</td>
  </tr>
</table>

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