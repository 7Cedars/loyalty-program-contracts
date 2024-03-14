// SPDX-License-Identifier: MIT

// define invariants that should always hold:

// INVARIANT that should ALWAYS hold: Points & vouchers should never be able to transfer beyond boundaries of a loyalty program. Loyalty program should always remain a closed system, despite use TBAs and external gift contracts.  
// Concretely: 
// 1. Amount of minted points should ALWAYS equal sum of points on cards minted + owner loyalty Program.  
// 2. Amount of minted vouchers should ALWAYS equal sum of vouchers on cards minted + loyalty Program.
// Also: 
// 3. getter view functions should never revert.
//

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployLoyaltyProgram} from "../../../script/DeployLoyaltyProgram.s.sol";
import {DeployMockLoyaltyGifts} from "../../../script/DeployLoyaltyGifts.s.sol";
import {LoyaltyProgram} from "../../../src/LoyaltyProgram.sol" ;
import {LoyaltyGift} from "../../mocks/LoyaltyGift.sol" ;
import {ContinueOnRevertHandler} from "./ContinueOnRevertHandler.t.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol" ;

contract ContinueOnRevertInvariantsTest is StdInvariant, Test {
  DeployLoyaltyProgram deployerLP;
  DeployMockLoyaltyGifts deployerLG;
  ContinueOnRevertHandler continueOnRevertHandler;

  struct ProgramData {
    LoyaltyProgram loyaltyProgram; 
    address[] loyaltyCards; 
    HelperConfig config; 
  }
  LoyaltyGift[] loyaltyGifts;
  ProgramData[] loyaltyPrograms;
  
  LoyaltyProgram loyaltyProgram; 
  HelperConfig helperConfig; 
  address[] cardAddresses; 
  
  function setUp() external {
    deployerLP = new DeployLoyaltyProgram();
    deployerLG = new DeployMockLoyaltyGifts();
    
    uint256 numberLoyaltyPrograms = 3; // number of LoyaltyPrograms that will be deployed.
    uint256 numberLoyaltyGifts = 4; // number of LoyaltyGifts that will be deployed.
    uint256 numberLoyaltyCards = 5; // number of LoyaltyGifts that will be deployed.

    // deploying loyaltyGift contracts
    for (uint256 j = 0; j < numberLoyaltyGifts; j++) { loyaltyGifts.push(deployerLG.run()); }
    
    // deploying loyaltyProgram contracts + loyaltyCards
    for (uint256 i = 0; i < numberLoyaltyPrograms; i++) { 
      (loyaltyProgram, helperConfig) = deployerLP.run(); // NB I am NOT saving config file here. 
      loyaltyProgram.mintLoyaltyCards(numberLoyaltyCards); 
      cardAddresses = new address[](0);  
      for (uint256 j = 0; j < numberLoyaltyCards; j++) { 
        cardAddresses.push(loyaltyProgram.getTokenBoundAddress(i)); 
        }

      loyaltyPrograms.push(ProgramData(
        loyaltyProgram, 
        cardAddresses, 
        helperConfig
      )); 
    }
 
    continueOnRevertHandler = new ContinueOnRevertHandler(loyaltyPrograms, loyaltyGifts, helperConfig); // (add here the contracts I need)
//     targetContract(address(continueOnRevertHandler));
  }

  // Invariant 1: Points minted at LoyaltyProgram can never end up at LoyaltyCards affiliated with another LoyaltyProgram.
  function invariant_pointsStayWithinLoyaltyProgram() public view {

    for (uint256 i = 0; i < loyaltyPrograms.length; i++) { 
      ProgramData programData; 
      address[] addresses; 
      uint256[] balances; 
      uint256 sumBalances; 
      
      // create array if addresses of loyalty Cards + program owner 
      programData = loyaltyPrograms[i]; 
      addresses = programData.loyaltyCards; 
      addresses.push(loyaltyPrograms[i].getOwner()); 
      // and array of 0 of length addresses array (0 = id for points). 
      uint256[addresses.length] pointsIds; 

      // using these two arrays get balances of cards and owners  
      balances = loyaltyPrograms[i].balanceOfBatch(cardAddresses, pointsIds);
      
      // Sum all balances.. 
      sumBalances = 0; 
      for (uint256 i = 0; i < balances.length; i++) { sumBalances + balances[i]; }
      
      // assert: sum of all balances should be same as initial supply. 
      // (I do not mint new points in test at this stage - can implement later). 
      assert (sumBalances = programData.config.initialSupply); 
    }
  }

  // Invariant 2: Gifts minted by LoyaltyProgram can never be redeemed at another LoyaltyProgram.
  function invariant_VouchersStayWithinLoyaltyProgram() public view {
  
  
  }

  // Invariant 3: Getter functions cannot revert.
  // This should be taken out of this inariant test, and be part of the "FailOnRevertInvariants"

//     function invariant_gettersCannotRevert() public view {
//       for (uint256 i = 0; i < loyaltyPrograms.length; i++) {
//           uint256 numberLCs = loyaltyPrograms[i].getNumberLoyaltyCardsMinted();
//           console.log("numberLCs: ", numberLCs);

//           loyaltyPrograms[i].getLoyaltyGiftsIsClaimable(address(loyaltyGifts[0]), 0);
//           loyaltyPrograms[i].getLoyaltyGiftsIsRedeemable(address(loyaltyGifts[0]), 0);
//           loyaltyPrograms[i].getOwner();

//           for (uint256 j = 0; j < numberLCs; j++) {
//             address tbaAddress; 
//             tbaAddress = loyaltyPrograms[i].getTokenBoundAddress(i);

//             loyaltyPrograms[i].getNonceLoyaltyCard(tbaAddress);
//             loyaltyPrograms[i].getBalanceLoyaltyCard(tbaAddress);
//             }
//           }
//         }
// }

// £ack Patrick C --  NB: invariant (stateful fuzz) testing in foundry see PC course at 3:23 - Implement! 
// See here: https://www.youtube.com/watch?v=wUjYK5gwNZs 
// at 3.31: invariant coding
// at 3.45: handlers coding