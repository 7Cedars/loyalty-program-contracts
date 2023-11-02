## Loyalty Program Solidity 
**Backend of blockchain based modular platform for loyalty programs**

This repository is meant as initial playground to try out, develop and test the necessary contracts.
For personal use only. 

## Idea and Design

- Create an open and modular blockchain based framework for loyalty programs. 
- Aimed at small and medium sized shops and companies. 
- eventually deploy on multiple blockchains. 
- Design of solidity backend is on Figma. 

## Development / TO DO 

- [x] Build, deploy, test ERC-20 based loyalty card contract. 
  - [x] tracks customer points. 
    - [x] this is simple ERC-20 implementation. 
    -  [x] points should be in unlimited supply. -- no inherent value. 
  - [x] tracks customer transactions. Transaction is a struct
    - [x] points 
    - [x] blocknumber 
    - [x] redeemed = false
  - [x] tracks list of whitelisted redeem contracts
    - [x] is mapping of addresses + indexed event. 
  - [x] Test if all these functions work. 
- [x] Build, deploy, test single ERC-721 NFT contract 
  - [x] takes points from any loyalty card contract. 
  - [x] create claim funtion: issues NFTs, on the basis of particular cost (# of points for instance.) 
    - [x] should take address that calls the function. (which is ERC-20 loyalty card contract)
    - [x] takes points AND transaction - one OR the other can be used. 
  - [x] issued NFTs remain linked to loyalty card contract that issued them. - possibly through 'approved address'? 
  - [x] The issued NFT should have description of redeemed value (e.g. a freeCoffee, attendance to party, etc); 
  - [x] create redeem function: delete / burn token, returns a redeemed = true.  
- [x] Import and test single ERC-721 NFT contract into ERC-20 based loyalty card contract
  - [x] whitelist ERC-721 contract
  - [x] Implement and test 'claim' function in ERC-20 loyalty card contract
    - [x] takes an address pointing to whitelisted list of ERC-721 NFT redeemed contracts
    - [x] calls its ERC-721 claim function   
    - [x] called by customer: sending points (implement events later).
    - [x] issues NFT. 
  - [ ] Implement and test 'redeem' function in ERC-20 loyalty card contract
    - [x] takes an integer pointing to ERC-721 NFT contracts. NB: these DO NOT HAVE TO BE whitelisted! 
    - [x] calls its ERC-721 redeem function
    - [ ] called through contract: sending NFT, getting burned. 
    - [ ] returns redeemed = true value.  
- [ ] Build, deploy, test ERC-721 contract Inheritance
  - [x] implement in existing ERC-721 contract. 
  - [x] Create two more ERC-721 contracts with different logics: one using events, one combination of the two. 
  - [ ] Whitelist them in ERC-20 contract.
  - [ ] test if different logics work. 
- [x] Build, deploy, test function to (de)select redeem contract for loyalty prgram. 
  - [x] pretty much add and delete addresses frm whitelist addresses.
- [ ] 

**At this stage I have a minimal PoC** 

- Next steps - optimise functionality and UI / UX: 
- Implement ERC-6551: Token Based Accounts. 
  - Actually creates a loyalty card (instead of address based account.)
  - Enables loyalty cards to be swapped, to have multiple loyalty cards of single vendor, etc etc. 
- Implement indirect funding
  - Don't know the exact name, but vendor should pay for gas - not customers. 
- Implement account abstraction
  - Enables easier sign up for customers. 
- Implement / experiment with different types of issuing and redeem logics. 
  - Create a range of ERC-721 redeem contracts, to show off possibilities.

## Resources used / I am indebted to:  
-  Patrick Collins' Learn Solidity, Blockchain Development, & Smart Contracts course. 
   -  deploy and test templates are from his course. 
   -    

## Foundry

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.


https://book.getfoundry.sh/

### Usage

#### Build

```shell
$ forge build
```

#### Test

```shell
$ forge test
```

#### Format

```shell
$ forge fmt
```

#### Gas Snapshots

```shell
$ forge snapshot
```

#### Anvil

```shell
$ anvil
```

#### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

#### Cast

```shell
$ cast <subcommand>
```

#### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
