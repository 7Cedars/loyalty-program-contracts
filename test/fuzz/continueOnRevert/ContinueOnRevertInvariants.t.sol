// SPDX-License-Identifier: MIT 

// define invariants that should always hold:  

// 1a. Loyalty points and Tokens only act as means of exchange between LoyaltyProgram and the loyalty Cards it minted.  
// 1b. Supply of tokens, points, cards is limited by amount minted by loyalty program only.  
// 2a. Token issuers can only mint loyaltyTokens - within set parameters.
// 2b. Token issuers supply is unlimited. 
// 3. getter view functions should never revert. 

pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployLoyaltyProgram} from "../../../script/DeployLoyaltyProgram.s.sol";
import {
  DeployLoyaltyGift,
  DeployMultipleLoyaltyGifts
  } from "../../../script/DeployLoyaltyGifts.s.sol";
import {LoyaltyProgram} from "../../../src/LoyaltyProgram.sol" ;
import {LoyaltyGift} from "../../../src/LoyaltyGift.sol" ;
import {ContinueOnRevertHandler} from "./ContinueOnRevertHandler.t.sol";

contract ContinueOnRevertInvariantsTest is StdInvariant, Test {
  DeployLoyaltyProgram deployerLP; 
  DeployLoyaltyGift deployerLT; 
  LoyaltyProgram[] loyaltyPrograms; 
  LoyaltyGift[] loyaltyTokens; 
  ContinueOnRevertHandler continueOnRevertHandler; 

  function setUp() external {
    deployerLP = new DeployLoyaltyProgram(); 
    deployerLT = new DeployLoyaltyGift(); 

    uint256 numberLPs = 3; // number of LoyaltyPrograms that will be deployed. 
    uint256 numberLTs = 4; // number of LoyaltyGifts that will be deployed. 
    uint256 numberLCs = 5; // number of LoyaltyCards that will be minted by each LoyaltyProgram. 
    
    for (uint256 i = 0; i < numberLPs; i++) { loyaltyPrograms.push(deployerLP.run()); }
    for (uint256 j = 0; j < numberLTs; j++) { loyaltyTokens.push(deployerLT.run()); }
    
    continueOnRevertHandler = new ContinueOnRevertHandler(loyaltyPrograms, loyaltyTokens); // (add here the contracts I need)
    targetContract(address(continueOnRevertHandler)); 
  }

  // Invariant 1: Points minted at LoyaltyProgram can never end up at LoyaltyCards affiliated with another LoyaltyProgram.    


  // Invariant 2: Tokens minted by LoyaltyProgram can never be redeemed at another LoyaltyProgram.  


  // Invariant 3: Getter functions cannot revert.  
  function invariant_gettersCantRevert() public view {
    for (uint256 i = 0; i < loyaltyPrograms.length; i++) { 
        uint256 numberLCs = loyaltyPrograms[i].getNumberLoyaltyCardsMinted();
        console.log("numberLCs: ", numberLCs); 

        loyaltyPrograms[i].getLoyaltyGiftsClaimable(address(loyaltyTokens[0]));
        loyaltyPrograms[i].getOwner();
        
        for (uint256 j = 0; j < numberLCs; j++) { 
          loyaltyPrograms[i].getBalanceLoyaltyCard(i); 
          loyaltyPrograms[i].getTokenBoundAddress(i);
          }  
        }
      }
} 