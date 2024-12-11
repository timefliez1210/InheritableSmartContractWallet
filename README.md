# Protocol Name 

[//]: # (contest-details-open)

### Prize Pool TO BE FILLED OUT BY CYFRIN

- Total Pool - 
- H/M -  
- Low - 

- Starts: 
- Ends: 

- nSLOC: 
- Complexity Score:

## About the Project

Inheriting crypto funds in cold or hot wallets is still an issue until this day, the Inheritance Manager contract implements a time-locked inheritance management system, enabling secure distribution of assets to designated beneficiaries. It uses time-based locks to ensure that assets are only accessible after a specified period. The contract maintains a list of beneficiaries, automating the allocation of inheritance based on predefined conditions. This system offers a trustless and transparent way to manage estate planning, ensuring assets are distributed as intended without the need for intermediaries.

Inheritance Manager can also be used as a backup for your wallet.

For a more in-depth documentation please have a look at the natspec, it is very detailed.

## Actors


Actors:
- ```Owner```: The Owner of the smart contract wallet
- ```Beneficiary```: Anyone set by the owner to inherit the smart contract and all it's balances.
- ```Trustee```: Not necessary role, but can be appointed by the beneficiearies in case underlaying estate values of the NFTs need to be reevaluated and/or the payout asset has to be changed.


[//]: # (contest-details-close)

[//]: # (scope-open)

## Scope (contracts)

```
All Contracts in `src` are in scope.
```
```js
src/
├── InheritanceManager.sol
├── NFTFactory.sol
├── modules/
    ├──Trustee.sol
```

### Notice:
All issues related to the NFT part are automatically considered low, EXCEPT the issue would result in a loss of funds. Issues with minting, BaseURI or anything else which DOES NOT result in
a loss of Ether or any other ERC20 tokens are absolutely not a priority, since the NFT logic is convinience only and relies on off-chain finality anyway.

## Compatibilities

```
Compatibilities:
  Blockchains:
      - Ethereum
  Tokens:
      - No limitations. Inheritance Manager needs to be compatible with ether and every ERC20 token.
```


[//]: # (scope-close)

[//]: # (getting-started-open)

## Setup

This is a standard Foundry project, to run it use:

```shell
$ forge install
```

```shell
$ forge build
```

### Test

```shell
$ forge test
```

```shell
$ forge coverage
```


[//]: # (getting-started-close)

[//]: # (known-issues-open)

## Known Issues

None.

[//]: # (known-issues-close)