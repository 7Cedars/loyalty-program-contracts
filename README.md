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
LoyaltyProgram. Get to deployment of contract! 
- [ ] Implement covering gas of users by LoyaltyProgram Owner
  - [ ] See https://learnweb3.io/lessons/using-metatransaction-to-pay-for-your-users-gas for a lesson on how to do this. 
  - [ ] Implement redeem token through signed message at till 
  - [ ] Implement (in front end) refund of money paid when claiming token. 
  - [ ] Implement gasless claiming of gift through signing message at till.
  - [ ] Optional: Implement tokens that DO NOT have NFT token - but can ONLY be claimed at till!  
- [ ] Build unit tests 
  - [ ] test should run with gas > 0 
  - [x] Do points get added to loyaltyCard (and not user address)? 
  - [x] Does adding and removing loyaltyTokenContract work? 
  - [x] Are loyalty cards freely transferrable to any contract address? 
  - [ ] Check use of signature works 
  - [ ] Check for signature replay attack 
- [ ] Build integration
  - [x] Does Minting loyaltyTokens by vendor work? 
  - [x] Does claim loyaltyTokens work - do tokens get redeemd by loyaltyCards (and not customers)? 
  - [ ] When tokens are finsihed - does it indeed stop issuing them? (are reverts bound by loyalty program)
  - [ ] Are points and tokens bound to loyalty cards?
- [ ] Build invariant tests
  - [ ] implement handler contract. 
  - [ ] implement invarient check cintract. 

LoyaltyToken 
- [ ] Create mock loyalty contract in this repository for testing purposes.  
- [ ] Create mutliple / more loyaltyToken contracts - also using chainlink external data: in seperate repositroy 
  - [ ] Create a seperate github repository for these contracts. -- only keep mock contract in this repository.  
  - [ ] Raffle. 
  - [ ] at least x amount of transactions in last x days... OR on last x number of Wednesday! 
  - [ ] Not having more than one of these tokens (otherwise you can claim many tokens, even though most points are from other day.)  
  - [ ] premium programs -> loyalty tokens only available on having particular 'premium token'. (for instance, cheaper free gifts, etc)
  - [ ] Buying token with $$ instead of points. (for instance, for customers buying themselves into premium program)
  - [ ] A DAO that distributes tokens for premium program. 
  - [ ] etc etc . 
  - [ ] 

Deployment 
- [ ] Build deployment scripts
- [x] Build mock interaction scripts 
  - [x] colleting points, claim and redeeming LoyaltyTokens
  - [x] colleting points, transfer loyaltyCard, claim tokens, transfer loyaltyCard, redeem tokens. 
  - [x] etc. -- come up with many different scenarios.
- [ ] Check: on what chains is ERC6551 deployed?  
  - [ ] Start setting up infra to deploy to several chains. 
- [ ] Run rest on forked testnets.
  - [ ] L1: Sepolia 
  - [ ] L2: optimus? 
  - [ ] L2: Arbitrum? 
  - [ ] Polygon zvEVM? 
- [ ] Deploy on actual testnet - and test.
- [ ] Deploy on actual chains! 


**At this stage I have a minimal PoC** 

- Next steps - optimise functionality and UI / UX:  
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
