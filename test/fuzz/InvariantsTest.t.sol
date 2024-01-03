// SPDX-License-Identifier: MIT 

// define invariants that should always hold:  

// 1a. Loyalty points and Tokens only act as means of exchange between LoyaltyProgram and the loyalty Cards it minted.  
// 1b. Supply of tokens, points, cards is limited by amount minted by loyalty program only.  
// 2a. Token issuers can only mint loyaltyTokens - within set parameters.
// 2b. Token issuers supply is unlimited. 
// 3. getter view functions should never revert. 

pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {
  DeployLoyaltyToken,
  DeployMultipleLoyaltyTokens
  } from "../../script/DeployLoyaltyTokens.s.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol" ;
import {LoyaltyToken} from "../../src/LoyaltyToken.sol" ;

contract InvariantTest is StdInvariant, Test {
  DeployLoyaltyProgram deployerLP; 
  LoyaltyProgram loyaltyProgram; 
  DeployLoyaltyToken deployerBasic; 
  DeployMultipleLoyaltyTokens deployerTokens; 
  LoyaltyToken oneCoffeeFor2500;
  LoyaltyToken oneCupCakeFor4500; 
  LoyaltyToken accessPartyFor50000;

  function setUp() external {
    deployerLP = new DeployLoyaltyProgram(); 
    loyaltyProgram = deployerLP.run();  
    deployerTokens = new DeployMultipleLoyaltyTokens(); 
    (oneCoffeeFor2500, oneCupCakeFor4500, accessPartyFor50000) = deployerTokens.run();  


  }


} 