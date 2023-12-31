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
  DeployLoyaltyToken,
  DeployMultipleLoyaltyTokens
  } from "../../../script/DeployLoyaltyTokens.s.sol";
import {LoyaltyProgram} from "../../../src/LoyaltyProgram.sol" ;
import {LoyaltyToken} from "../../../src/LoyaltyToken.sol" ;
import {ContinueOnRevertHandler} from "./ContinueOnRevertHandler.t.sol";

contract ContinueOnRevertInvariantsTest is StdInvariant, Test {
  DeployLoyaltyProgram deployerLP; 
  DeployLoyaltyToken deployerLT; 
  LoyaltyProgram[] loyaltyPrograms; 
  LoyaltyToken[] loyaltyTokens; 
  ContinueOnRevertHandler continueOnRevertHandler; 

  function setUp() external {
    deployerLP = new DeployLoyaltyProgram(); 
    deployerLT = new DeployLoyaltyToken(); 

    uint256 numberLPs = 5;
    uint256 numberLTs = 15;
    
    for (uint256 i = 0; i < numberLPs; i++) { loyaltyPrograms.push(deployerLP.run()); }
    for (uint256 j = 0; j < numberLTs; j++) { loyaltyTokens.push(deployerLT.run()); }
    
    continueOnRevertHandler = new ContinueOnRevertHandler(loyaltyPrograms, loyaltyTokens); // (add here the contracts I need)
    targetContract(address(continueOnRevertHandler)); 
  }



  function invariant_gettersCantRevert() public view {
    for (uint256 i = 0; i < loyaltyPrograms.length; i++) { 
        uint256 numberLCs = loyaltyPrograms[i].getNumberLoyaltyCardsMinted();
        console.log("numberLCs: ", numberLCs); 

        loyaltyPrograms[i].getLoyaltyToken(address(loyaltyTokens[0]));
        loyaltyPrograms[i].getOwner();
        
        for (uint256 j = 0; j < numberLCs; j++) { 
          loyaltyPrograms[i].getBalanceLoyaltyCard(i); 
          loyaltyPrograms[i].getTokenBoundAddress(i);
          }  
        }
      }
} 