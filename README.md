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
So, minimal PoC of LoyaltyProgram is finished. Next steps (Do these while completing PatrickC's course on Foundry)
- [x] Add reentrancy guard to LoyaltyProgram. See note on safeTransferFrom in erc1155. 
- [x] Build unit tests 
  - [x] Do points get added to loyaltyCard (and not user address)? 
  - [x] Does adding and removing loyaltyTokenContract work? 
  - [ ] Are loyalty cards freely transferrable to any contract address? 
- [ ] Build integration tests 
  - [x] Does Minting loyaltyTokens by vendor work? 
  - [ ] Does claim loyaltyTokens work - do tokens get redeemd by loyaltyCards (and not customers)? 
  - [ ] When tokens are finsihed - does it indeed stop issuing them? (are reverts bound by loyalty program)
  - [ ] Are points and tokens bound to loyalty cards?   
- [ ] Build interactions and scenarios - best done in seperate github repository! 
  - [ ] colleting points, claim and redeeming LoyaltyTokens
  - [ ] colleting points, transfer loyaltyCard, claim tokens, transfer loyaltyCard, redeem tokens. 
  - [ ] etc. -- come up with many different scenarios. 
  - [ ] Place all these in seperate repository. 
  - [ ] Create mock loyalty contract in this repository for testing purposes.  
- [ ] Implement gasless transaction for loyaltyCard holdres - VENDOR should pay gas!
- [ ] Rerun all tests - now with gas cost > 0 
- [ ] Create mutliple / more loyaltyToken contracts - also using chainlink external data. 
  - [ ] Raffle. 
  - [ ] at least x amoung of transactions in last  x days... 
  - [ ] premium programs -> loyalty tokens only available on having particular 'premium token'. 
  - [ ] Buying token with $$ instead of points. 
  - [ ] etc etc . 
- [ ] Focus on developing front end - see 'loyalty-program-next' folder.  
- [ ] Check: on what chains is ERC6551 deployed?  
  - [ ] Start setting up infra to deploy to several chains. 
- [ ] Run rest on forked testnets.
  - [ ] L1: Sepolia 
  - [ ] L2: optimus? 
  - [ ] L2: Arbitrum? 
  - [ ] ...? 
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
