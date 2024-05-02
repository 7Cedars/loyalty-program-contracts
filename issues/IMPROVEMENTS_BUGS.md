## Loyalty Program Next 
**Frontend of blockchain based modular platform for loyalty programs**

This repository is meant as initial playground to develop and test front end as I develop to solidity backend. 
Even though repository is public, For now, it is for personal use only. 

## Idea and Design
- Create an open and modular blockchain based framework for loyalty programs. 
- Aimed at small and medium sized shops and companies. 
- eventually deploy on multiple blockchains. 
- Design of solidity frontend is on my Figma. 

# Deploy todo
- [ ]  Deploy on Polygon mumbai chain. WalletConetc's email login works in this chain. 
- [ ]  Deploy on other chains?  

## Know bugs (in order of priority)
- [ ] CardsToProgramToGifts.t.sol sometimes fails, sometimes not. Find out why & fix. 
- [ ] HelperConfig.s.sol deploys a new LoyaltyCard6551Account instance everytime it is run
  - [ ] should use CREATE2 for determinsitc deployment 
  - [ ] should check if already deployed. 
- [ ]    

## Improvements to implement (in order of priority)
- [ ] Integrate with account abstraction. (for version 2) 
