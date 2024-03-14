// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// needs a setup / constructor that 
// - set ups 0 - 3 loyalty programs 
// - set ups 0 - 3 loyalty gift programs. 
// modifier that has programs select, mint 0 - many points, cards, vouchers. 

// Functions: 
// - safe transfer any token id to any (card, program) address that emerged from setup.    
// - claim gifts from loyalty card at any loyalty program 
// - redeem voucher (if availabe at card) at any loyalty program. 

// if max 3 loyalty programs, should still be about 30% succesful :D  
// Note: should also test for scenarios where no program or gifts exist 


import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployLoyaltyProgram} from "../../../script/DeployLoyaltyProgram.s.sol";
import {DeployMockLoyaltyGifts} from "../../../script/DeployLoyaltyGifts.s.sol";
import {LoyaltyProgram} from "../../../src/LoyaltyProgram.sol" ;
import {LoyaltyGift} from "../../mocks/LoyaltyGift.sol" ;
import {HelperConfig} from "../../../script/HelperConfig.s.sol" ;

contract ContinueOnRevertHandler is Test {
  DeployLoyaltyProgram deployerLP;
  DeployMockLoyaltyGifts deployerLT;
  struct ProgramData {
    LoyaltyProgram loyaltyProgram; 
    address[] loyaltyCards; 
    HelperConfig config; 
  }
  ProgramData[] loyaltyPrograms;
  LoyaltyGift[] loyaltyTokens;
  HelperConfig helperConfig; 
  ContinueOnRevertHandler handler;
  uint256 numberLCards; 
  
  constructor(ProgramData[] memory _loyaltyPrograms, LoyaltyGift[] memory _loyaltyTokens, HelperConfig _helperConfig) {
        loyaltyPrograms = _loyaltyPrograms;
        loyaltyTokens = _loyaltyTokens;
        helperConfig = _helperConfig;
  }

} 

// needs modifier: if no cards, vouchers or poiints: mint, select gifts, mint vouchers. 

//   function mintPointsCardsAndTokens(uint256 seedPoints, uint256 seedCards, uint256 seedToken) public {

//     seedPoints = bound(seedPoints, 5000, 50000000);
//     seedCards = bound(seedCards, 2, 12);
//     seedToken = bound(seedToken, 1, 25);

//     for (uint i; i < loyaltyPrograms.length; i++) {
//       vm.startPrank(loyaltyPrograms[i].getOwner());
//       loyaltyPrograms[i].mintLoyaltyPoints(seedPoints);
//       loyaltyPrograms[i].mintLoyaltyCards(seedCards);

//       for (uint j; j < loyaltyTokens.length; j++) {
//         loyaltyPrograms[i].addLoyaltyGiftContract(payable(address(loyaltyTokens[j])));
//         loyaltyPrograms[i].mintLoyaltyGifts(payable(address(loyaltyTokens[j])), seedToken);
//       }
//       vm.stopPrank();
//     }
//   }
// }
