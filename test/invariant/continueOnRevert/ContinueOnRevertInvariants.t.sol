// SPDX-License-Identifier: MIT
// £ack: NB: invariant (stateful fuzz) testing from foundry course by Patrick Collins see part III (https://www.youtube.com/watch?v=wUjYK5gwNZs) at 3:23  

// define INVARIANT that should ALWAYS hold: 
// - Points & vouchers should never be able to transfer beyond boundaries of a loyalty program. 
// - Loyalty program should always remain a closed system, despite use TBAs and external gift contracts.  
//
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
 import {MockLoyaltyGift} from "../../mocks/MockLoyaltyGift.sol" ;
import {ContinueOnRevertHandlerPrograms} from "./ContinueOnRevertHandlerPrograms.t.sol";
import {ContinueOnRevertHandlerCards} from "./ContinueOnRevertHandlerCards.t.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol" ;

contract ContinueOnRevertInvariantsTest is StdInvariant, Test {
  DeployLoyaltyProgram deployerLP;
  DeployMockLoyaltyGifts deployerLG;
  ContinueOnRevertHandlerPrograms continueOnRevertHandlerPrograms;
  ContinueOnRevertHandlerCards continueOnRevertHandlerCards;
  LoyaltyProgram loyaltyProgram; 
  HelperConfig helperConfig; 
  uint256 INITIAL_SUPPLY_POINTS = 5000000000; 
  uint256 INITIAL_SUPPLY_VOUCHERS = 15; 

  struct ProgramData {
    LoyaltyProgram loyaltyProgram; 
    address owner; 
    address[] loyaltyCards; 
    HelperConfig config; 
  }
  ProgramData[] programsData;

  address[] userAddresses; 
  uint256[] userPrivatekeys; 
  LoyaltyProgram[] loyaltyPrograms;
  MockLoyaltyGift[] loyaltyGifts;
  address[] cardAddresses; 
  address[] allCardAddresses;
  
  function testA() public {} // to have foundry ignore this file in coverage report. see £ack https://ethereum.stackexchange.com/questions/155700/force-foundry-to-ignore-contracts-during-a-coverage-report

  function setUp() external {
    deployerLP = new DeployLoyaltyProgram();
    deployerLG = new DeployMockLoyaltyGifts();

    uint256 numberLoyaltyPrograms = 3; // number of programsData.
    uint256 numberLoyaltyGifts = 4; // number of LoyaltyGifts.
    uint256 numberLoyaltyCards = 5; // number of LoyaltyCards.

    // deploying loyaltyGift contracts
    for (uint256 i = 0; i < numberLoyaltyGifts; i++) { loyaltyGifts.push(deployerLG.run()); }
    
    // deploying loyaltyProgram contracts
    for (uint256 i = 0; i < numberLoyaltyPrograms; i++) { 
      address owner;
      cardAddresses = new address[](0);
      (loyaltyProgram, helperConfig) = deployerLP.run(); 
      owner = loyaltyProgram.getOwner(); 

      vm.startPrank(owner); 
      loyaltyProgram.mintLoyaltyPoints(INITIAL_SUPPLY_POINTS); 
      loyaltyProgram.mintLoyaltyCards(numberLoyaltyCards); 
      vm.stopPrank(); 
      
      for (uint256 j = 0; j < numberLoyaltyCards; j++) { 
        address tempAddress = loyaltyProgram.getTokenBoundAddress(j); 
        cardAddresses.push(tempAddress);
        allCardAddresses.push(tempAddress); 
      }
      loyaltyPrograms.push(loyaltyProgram); 
      
      programsData.push(ProgramData(
        loyaltyProgram, 
        owner, 
        cardAddresses,  
        helperConfig
      )); 
    }
 
    continueOnRevertHandlerPrograms = new ContinueOnRevertHandlerPrograms(
      loyaltyPrograms, 
      allCardAddresses, 
      loyaltyGifts, 
      helperConfig, 
      INITIAL_SUPPLY_VOUCHERS 
      ); 
    continueOnRevertHandlerCards = new ContinueOnRevertHandlerCards(
      loyaltyPrograms, 
      allCardAddresses, 
      loyaltyGifts, 
      helperConfig
      ); 
    targetContract(address(continueOnRevertHandlerPrograms));
    targetContract(address(continueOnRevertHandlerCards));
  }

  // Invariant 1: Points minted at LoyaltyProgram can never end up at LoyaltyCards affiliated with another LoyaltyProgram.
  function invariant_TestPointsStayWithinLoyaltyProgram() public view {

    for (uint256 i = 0; i < programsData.length; i++) { 
      ProgramData memory programData; 
      uint256[] memory cardBalances; 
      uint256 sumCardBalances; 
      uint256 programBalance; 

      programData = programsData[i];
      uint256[] memory pointsIds = new uint256[](programData.loyaltyCards.length); // initiates as an array of 0s.. 

      // using these two arrays get balances of cards and owners  
      cardBalances = programData.loyaltyProgram.balanceOfBatch(programData.loyaltyCards, pointsIds);
      programBalance = programData.loyaltyProgram.balanceOf(programData.loyaltyProgram.getOwner(), 0);
      
      // Sum all balances.. 
      sumCardBalances = 0; 
      for (uint256 j = 0; j < cardBalances.length; j++) { sumCardBalances = sumCardBalances + cardBalances[j]; }
      
      // assert: sum of all balances should be same as initial supply. 
      // (I do not mint new points in test at this stage - can implement later). 
      assert(sumCardBalances + programBalance == INITIAL_SUPPLY_POINTS); 
    }
  }

  // Invariant 2: Gifts minted by LoyaltyProgram can never be redeemed at another LoyaltyProgram.
  function invariant_TestVouchersStayWithinLoyaltyProgram() public view {
    uint256[] memory cardsBalance; 
    uint256 sumCardBalances; 
    uint256 programBalance; 
    ProgramData memory programData;
    MockLoyaltyGift loyaltyGift; 
    address programOwner;

    /**
     * @notice: testing if for each program, each selected gift has an amount of vouchers that can be 
     * divided by the amount of INITIAL_SUPPLY_VOUCHERS. If this is not the case, vouchers bled into 
     * (cards of) other programs. 
     * 
     */
    for (uint256 i = 0; i < programsData.length; i++) {    
      for (uint256 j = 0; j < loyaltyGifts.length; j++) {
        for (uint256 voucherId = 3; voucherId <= 6; voucherId++) {// for now am using the fixed length ot tokenIds. 
          programData = programsData[i]; 
          programOwner = programData.loyaltyProgram.getOwner(); 
          loyaltyGift = loyaltyGifts[j];
          uint256[] memory idsArray = new uint256[](programData.loyaltyCards.length);
          for (uint256 k = 0; k < programData.loyaltyCards.length; k++) {
            idsArray[k] = voucherId; 
          }
          cardsBalance = loyaltyGift.balanceOfBatch(programData.loyaltyCards, idsArray);
          programBalance = loyaltyGift.balanceOf(address(programData.loyaltyProgram), voucherId);
          // Sum all balances.. 
          sumCardBalances = 0; 
          for (uint256 l = 0; l < cardsBalance.length; l++) { sumCardBalances = sumCardBalances + cardsBalance[l]; }
          sumCardBalances = sumCardBalances + programBalance; 

          // Assert that the sum of balances of one voucher across cards and program can be divide by INITIAL_SUPPLY_VOUCHERS. 
          assert(sumCardBalances % INITIAL_SUPPLY_VOUCHERS == 0);
        }
      }
    }
  } 

  // Invariant 3: Getter functions cannot revert.
  // This should be taken out of this inariant test, and be part of the "FailOnRevertInvariants"

    function invariant_gettersCannotRevert() public view {
      for (uint256 i = 0; i < programsData.length; i++) {
          uint256 numberLCs = programsData[i].loyaltyProgram.getNumberLoyaltyCardsMinted();
          // console.log("numberLCs: ", numberLCs);

          programsData[i].loyaltyProgram.getLoyaltyGiftIsClaimable(address(loyaltyGifts[0]), 0);
          programsData[i].loyaltyProgram.getLoyaltyGiftIsRedeemable(address(loyaltyGifts[0]), 0);
          programsData[i].loyaltyProgram.getOwner();

          for (uint256 j = 0; j < numberLCs; j++) {
            address tbaAddress; 
            tbaAddress = programsData[i].loyaltyProgram.getTokenBoundAddress(i);

            programsData[i].loyaltyProgram.getNonceLoyaltyCard(tbaAddress);
            programsData[i].loyaltyProgram.getBalanceLoyaltyCard(tbaAddress);             

            }
          }
        }

  // Helper Functions 
    function _getBalanceVouchers( uint256 loyaltyProgramSeed ) private view returns (LoyaltyProgram) 
    {
      return loyaltyPrograms[loyaltyProgramSeed % loyaltyPrograms.length];
      }

}

// £ack Patrick C --  NB: invariant (stateful fuzz) testing in foundry see PC course at 3:23 - Implement! 
// See here: https://www.youtube.com/watch?v=wUjYK5gwNZs 
// at 3.31: invariant coding
// at 3.45: handlers coding