// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// needs a setup / constructor that 
// - set ups 0 - 5 loyalty programs 
// - set ups 1 - 3 loyalty gift programs. 
// modifier that has programs select, mint 0 - many points, cards, vouchers. 

// Functions: 
// - safe transfer any token id to any (card, program) address that emerged from setup.    
// - claim gifts from loyalty card at any loyalty program 
// - redeem voucher (if availabe at card) at any loyalty program. 

// if max 5 loyalty programs, should still be about 20% succesful :D  


// import {Test} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {DeployLoyaltyProgram} from "../../../script/DeployLoyaltyProgram.s.sol";
// import { DeployLoyaltyGifts } from "../../../script/DeployLoyaltyGifts.s.sol";
// import {LoyaltyProgram} from "../../../src/LoyaltyProgram.sol" ;
// import {LoyaltyGift} from "../../../src/LoyaltyGift.sol" ;

// contract ContinueOnRevertHandler is Test {
//   DeployLoyaltyProgram deployerLP;
//   DeployLoyaltyGift deployerLT;
//   LoyaltyProgram[] loyaltyPrograms;
//   LoyaltyGift[] loyaltyTokens;
//   ContinueOnRevertHandler handler;

//   constructor(LoyaltyProgram[] memory _loyaltyPrograms, LoyaltyGift[] memory _loyaltyTokens) {
//         loyaltyPrograms = _loyaltyPrograms;
//         loyaltyTokens = _loyaltyTokens;
//   }

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
