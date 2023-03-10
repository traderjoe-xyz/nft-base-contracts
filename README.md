# NFT base contracts

Set of contracts to be used as a base for NFT collections. Three contracts are included as of now:
- `ERC1155BaseUpgradeable` an 1155 contract, in the upgradeable version
- `ERC721ABaseUpgradeable` an ERC721A contract (v4.2.0), in the upgradeable version
- `OZNFTBaseUpgradeable` a regular ERC721 that implements the LayerZero bridging mechanism, to launch multichain NFTs. In the upgradeable version.

All these contracts implements the same base layer:
- Two steps ownership transfers
- Role management
- Pausable
- ERC165
- ERC2981
- Subscription to the OpenSea Filter Registry (can be disabled)
- `WithdrawAVAX` method to send sale proceeds to the project owner minus a launchpad fee


OZNFT contracts have been forked from the Layer Zero [solidity examples](https://github.com/LayerZero-Labs/solidity-examples) repo, to replace the `Ownable` contract by `PendingOwnable`.

___

## Install dependencies

To install dependencies, run the following to install dependencies:

```
forge install
```

___

## Tests

To run tests, run the following command:

```
forge test
```