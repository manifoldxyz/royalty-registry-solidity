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
