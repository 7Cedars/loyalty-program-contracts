## Loyalty Program Solidity 
**Backend of blockchain based modular platform for loyalty programs**

This repository is meant as initial playground to try out, develop and test the necessary contracts.
For personal use only. 

## Idea and Design
- Create an open and modular blockchain based framework for loyalty programs. 
- Aimed at small and medium sized shops and companies. 
- eventually deploy on multiple blockchains. 
- Design of solidity backend is on Figma. 

- [ ] Deploy on actual testnet - and test.
- [ ] Deploy on actual chains! 

## (Temp) move to Loyalty Gifts Repo 
- [ ] Create mutliple / more loyaltyToken contracts - also using chainlink external data: in seperate repositroy 
  - [ ] Create a seperate github repository for these contracts. -- only keep mock contract in this repository.  
  - [ ] Raffle. 
  - [ ] at least x amount of transactions in last x days... OR on last x number of Wednesday! 
  - [ ] Not having more than one of these tokens (otherwise you can claim many tokens, even though most points are from other day.)  
  - [ ] premium programs -> loyalty tokens only available on having particular 'premium token'. (for instance, cheaper free gifts, etc)
  - [ ] Buying token with $$ instead of points. (for instance, for customers buying themselves into premium program)
  - [ ] A DAO that distributes tokens for premium program. 
  - [ ] etc etc. 

## testing
- [ ] Build invariant tests
  - [ ] implement handler contract. 
  - [ ] implement invarient check cintract. 
- [ ] When tokens are finsihed - does it indeed stop issuing them? (are reverts bound by loyalty program)
- [ ] Are points and tokens bound to loyalty cards?
- [ ] Run rest on forked testnets.
  - [x] L1: Sepolia 
  - [ ] OP Sepolia ( = testnet Optimism )
  - [ ] Arbitrum Sepolia See here: https://docs.arbitrum.io/for-devs/concepts/public-chains 
  - [ ] Polygon zvEVM? 

## known bugs
- [ ] @LoyaltyContract: does not check contract interface (ERC-165) when adding loyaltygift contract addresses. I tried to fix this, but somehow couldn't get it to work.  
- [ ] @LoyaltyContract & LoyaltyCard6551Account: TBAs are linked to 1155 minted NFT. Problem is: these tokens are never fully non-fungible: additional tokens CAN BE MINTED. This means their might by MORE THAN ONE PERSON HAVING ACCESS TO LOYALTY CARDS. See also the check that I do in bespoke ERC6551 account. This is one huge security hole. 
- [ ] 

## Optimisations
- [ ] @LoyaltyProgram, mintLoyaltyCards: can I batch calls to registry? -- this would save A LOT of GAS. 
- [ ] @All: make sure I use automatic optimisations! 
- [ ] @LoyaltyCard6551Account: upgrade to AccountV3. See https://github.com/tokenbound/contracts/blob/main/src/AccountV3.sol 
- [ ] 

## Improvements
- [ ] make ownership of LoyaltyProgram more flexible. 
- [ ] Implement account abstraction for customers.  
- [ ] create range of token contracts, to show off possibilities. (in seperate repo).  
- [ ] 

## Resources used / I am indebted to:  
-  Patrick Collins' Learn Solidity, Blockchain Development, & Smart Contracts course. 
   -  deploy and test templates are from his course. 
   -  TokenBound 
   -  OpenZeppelin - base for all contracts. 
   -  Foundry? Awesome framework for solidity dev. 