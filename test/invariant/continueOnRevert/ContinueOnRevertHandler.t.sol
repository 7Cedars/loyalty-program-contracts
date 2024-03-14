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


// import {Test} from "forge-std/Test.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployLoyaltyProgram} from "../../../script/DeployLoyaltyProgram.s.sol";
import {DeployMockLoyaltyGifts} from "../../../script/DeployLoyaltyGifts.s.sol";
import {LoyaltyProgram} from "../../../src/LoyaltyProgram.sol" ;
import {LoyaltyGift} from "../../mocks/LoyaltyGift.sol" ;
import {HelperConfig} from "../../../script/HelperConfig.s.sol" ;

contract ContinueOnRevertHandler is Test  {
  DeployLoyaltyProgram deployerLP;
  DeployMockLoyaltyGifts deployerLT;

  LoyaltyProgram[] loyaltyPrograms;
  address[] loyaltyCards;
  LoyaltyGift[] loyaltyGifts;
  
  HelperConfig helperConfig; 
  ContinueOnRevertHandler handler;
  uint256 numberLCards; 

  // first programs needs to select gift programs. 
  
  constructor(
    LoyaltyProgram[] memory _loyaltyPrograms,  
    address[] memory _loyaltyCards,  
    LoyaltyGift[] memory _loyaltyGifts, 
    HelperConfig _helperConfig
    ) {
      loyaltyPrograms = _loyaltyPrograms;
      loyaltyCards = _loyaltyCards; 
      loyaltyGifts = _loyaltyGifts;
      helperConfig = _helperConfig;
    }

    // some functions need to run more often than others 
    // NB: this does not change the seed values - meaning it just reruns the exact same call - which is pretyy much useless..  
    modifier runsMultipliedBy (uint256 multiplier) {
      for (uint256 i = 0; i < multiplier; i++) { 
        _; 
      }
    } 

    // have Program select and mint vouchers 
    // -- needs to result in sufficient amount of selections. 
    function selectLoyaltyGiftAndMintVouchers(
      uint256 loyaltyProgramSeed, 
      uint256 giftProgramSeed,
      uint256 giftIdSeed, 
      uint256 mintSeed 
      ) public {
        LoyaltyProgram loyaltyProgram = _getLoyaltyProgram(loyaltyProgramSeed); 
        LoyaltyGift giftProgram = _getGiftProgram(giftProgramSeed); 
        // this is all still a bit convoluted
        uint256[] memory tokenised = giftProgram.getTokenised();
        uint256 giftId = giftIdSeed % tokenised.length;
        uint256[] memory voucherIds = new uint256[](1); 
        uint256[] memory voucherMints  = new uint256[](1);
        voucherIds[0] = giftId; 
        voucherMints[0] = mintSeed % 15; 

        vm.prank(loyaltyProgram.getOwner()); 
          loyaltyProgram.addLoyaltyGift(address(giftProgram), giftId); 

        if (tokenised[giftId] == 1) {
          vm.prank(loyaltyProgram.getOwner()); 
          loyaltyProgram.mintLoyaltyVouchers(
            address(giftProgram), 
            voucherIds, 
            voucherMints
            ); 
          }
    }

    /**
     * @notice loyaltyPrograms transfer points to ANY known card address
     * 
     * @dev the max amount is now set to 5000. Note absent check on amount points program. 
     * 
     */
    function distributePoints(
      uint256 loyaltyProgramSeed, 
      uint256 loyaltyCardSeed, 
      uint256 amountPointsSeed
      ) public {
      LoyaltyProgram loyaltyProgram = _getLoyaltyProgram(loyaltyProgramSeed);
      address loyaltyCard = loyaltyCards[loyaltyCardSeed % loyaltyCards.length]; 
      uint256 amountPoints = amountPointsSeed % 5000; 
      address owner = loyaltyProgram.getOwner();

      vm.prank(owner); 
      loyaltyProgram.safeTransferFrom(
        owner, 
        loyaltyCard, 
        0, 
        amountPoints, 
        ""
      ); 
    }

    // // have a random card try to transfer to random other known address: card, program or gift contract 
    // function transferPoints(
    //   uint256 loyaltyCardSeed, 
    //   uint256 loyaltyProgramSeed, 
      
    //   uint256 amountPointsSeed
    // ) public {

    // }

    // // have ANY known card try to claim gift at ANY known loyalty Program
    // function claimGifts() public {

    // }

    // // have ANY known card with voucher try to redeem voucher at ANY known loyalty Program
    // function redeemVoucher() public {

    // }


    // Helper Functions 
    function _getLoyaltyProgram( uint256 loyaltyProgramSeed ) private view returns (LoyaltyProgram) 
    {
      return loyaltyPrograms[loyaltyProgramSeed % loyaltyPrograms.length];
      }

    function _getGiftProgram( uint256 giftProgramSeed ) private view returns (LoyaltyGift) 
    {
      return loyaltyGifts[giftProgramSeed % loyaltyGifts.length];
      }

    // NB: I DO need a list of ALL loyalty Card Addresses! 
    function _getLoyaltyCard( uint256 loyaltyCardSeed ) private view returns (address) 
    {
      return loyaltyCards[loyaltyCardSeed % loyaltyCards.length];
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

//       for (uint j; j < loyaltyGifts.length; j++) {
//         loyaltyPrograms[i].addLoyaltyGiftContract(payable(address(loyaltyGifts[j])));
//         loyaltyPrograms[i].mintLoyaltyGifts(payable(address(loyaltyGifts[j])), seedToken);
//       }
//       vm.stopPrank();
//     }
//   }
// }
