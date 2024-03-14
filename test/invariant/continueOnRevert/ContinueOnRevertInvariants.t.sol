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
    address owner; 
    address[] loyaltyCards; 
    HelperConfig config; 
  }
  ProgramData[] programDatas;
  LoyaltyProgram[] loyaltyPrograms; 
  LoyaltyGift[] loyaltyGifts;
  address[] cardAddresses;
  address[] allCardAddresses;  
  LoyaltyProgram loyaltyProgram; 
  HelperConfig helperConfig; 
  
  function setUp() external {
    deployerLP = new DeployLoyaltyProgram();
    deployerLG = new DeployMockLoyaltyGifts();

    // implement fuzzing later. 
    // seedPoints = bound(seedPoints, 5000, 50000000);
    // seedCards = bound(seedCards, 2, 12);
    // seedToken = bound(seedToken, 1, 25);
    // NB: just use "seed % 3 == 0, 1, 2," kind of logic" See Patrick C 3:56 //  
    uint256 numberprogramDatas = 3; // number of programDatas that will be deployed.
    uint256 numberLoyaltyGifts = 4; // number of LoyaltyGifts that will be deployed.
    uint256 numberLoyaltyCards = 5; // number of LoyaltyGifts that will be deployed.

    // deploying loyaltyGift contracts
    for (uint256 j = 0; j < numberLoyaltyGifts; j++) { loyaltyGifts.push(deployerLG.run()); }
    
    // deploying loyaltyProgram contracts + loyaltyCards
    for (uint256 i = 0; i < numberprogramDatas; i++) { 
      (loyaltyProgram, helperConfig) = deployerLP.run(); // NB I am NOT saving config file here. 
       uint256 initialSupply; 
      ( , , initialSupply, , , , ) = helperConfig.activeNetworkConfig(); 

      vm.startPrank(loyaltyProgram.getOwner()); 
      loyaltyProgram.mintLoyaltyCards(numberLoyaltyCards); 
      loyaltyProgram.mintLoyaltyPoints(initialSupply); // I can do this simpler and more dynamically. 
      vm.stopPrank(); 
      
      cardAddresses = new address[](0);  
      for (uint256 j = 0; j < numberLoyaltyCards; j++) { 
        address tempAddress = loyaltyProgram.getTokenBoundAddress(j); 
        cardAddresses.push(tempAddress);
        allCardAddresses.push(tempAddress); 
      }
      address owner = loyaltyProgram.getOwner(); 
      loyaltyPrograms.push(loyaltyProgram); 
      
      programDatas.push(ProgramData(
        loyaltyProgram, 
        owner, 
        cardAddresses,  
        helperConfig
      )); 
    }
 
    continueOnRevertHandler = new ContinueOnRevertHandler(loyaltyPrograms, allCardAddresses, loyaltyGifts, helperConfig); // (add here the contracts I need)
    targetContract(address(continueOnRevertHandler));
  }

  // Invariant 1: Points minted at LoyaltyProgram can never end up at LoyaltyCards affiliated with another LoyaltyProgram.
  function invariant_pointsStayWithinLoyaltyProgram() public view {

    for (uint256 i = 0; i < programDatas.length; i++) { 
      ProgramData memory programData; 
      uint256[] memory cardBalances; 
      uint256 sumCardBalances; 
      uint256 ownerBalance; 
      uint256 initialSupply; 

      programData = programDatas[i];
      uint256[] memory pointsIds = new uint256[](programData.loyaltyCards.length);
      ( , , initialSupply, , , , ) = programData.config.activeNetworkConfig(); 

      // using these two arrays get balances of cards and owners  
      cardBalances = programData.loyaltyProgram.balanceOfBatch(programData.loyaltyCards, pointsIds);
      ownerBalance = programData.loyaltyProgram.balanceOf(programData.loyaltyProgram.getOwner(), 0);
      
      // Sum all balances.. 
      sumCardBalances = 0; 
      for (uint256 j = 0; j < cardBalances.length; j++) { sumCardBalances = sumCardBalances + cardBalances[j]; }
      
      // assert: sum of all balances should be same as initial supply. 
      // (I do not mint new points in test at this stage - can implement later). 
      assert(sumCardBalances + ownerBalance == initialSupply); 
    }
  }
}

  // Invariant 2: Gifts minted by LoyaltyProgram can never be redeemed at another LoyaltyProgram.
  // function invariant_VouchersStayWithinLoyaltyProgram() public view {
  
  
  // }

  // Invariant 3: Getter functions cannot revert.
  // This should be taken out of this inariant test, and be part of the "FailOnRevertInvariants"

//     function invariant_gettersCannotRevert() public view {
//       for (uint256 i = 0; i < programDatas.length; i++) {
//           uint256 numberLCs = programDatas[i].getNumberLoyaltyCardsMinted();
//           console.log("numberLCs: ", numberLCs);

//           programDatas[i].getLoyaltyGiftsIsClaimable(address(loyaltyGifts[0]), 0);
//           programDatas[i].getLoyaltyGiftsIsRedeemable(address(loyaltyGifts[0]), 0);
//           programDatas[i].getOwner();

//           for (uint256 j = 0; j < numberLCs; j++) {
//             address tbaAddress; 
//             tbaAddress = programDatas[i].getTokenBoundAddress(i);

//             programDatas[i].getNonceLoyaltyCard(tbaAddress);
//             programDatas[i].getBalanceLoyaltyCard(tbaAddress);
//             }
//           }
//         }
// }

// £ack Patrick C --  NB: invariant (stateful fuzz) testing in foundry see PC course at 3:23 - Implement! 
// See here: https://www.youtube.com/watch?v=wUjYK5gwNZs 
// at 3.31: invariant coding
// at 3.45: handlers coding