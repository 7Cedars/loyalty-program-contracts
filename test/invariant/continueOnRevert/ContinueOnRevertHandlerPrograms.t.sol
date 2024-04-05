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

contract ContinueOnRevertHandlerPrograms is Test  {
  DeployLoyaltyProgram deployerLP;
  DeployMockLoyaltyGifts deployerLT;
  event Log(string message);

  LoyaltyProgram[] loyaltyPrograms;
  address[] loyaltyCards;
  LoyaltyGift[] loyaltyGifts;
  
  HelperConfig helperConfig; 
  ContinueOnRevertHandlerPrograms handler;
  uint256 numberLCards; 
  uint256[] supplyVouchers; 
  
  constructor(
    LoyaltyProgram[] memory _loyaltyPrograms,  
    address[] memory _loyaltyCards,  
    LoyaltyGift[] memory _loyaltyGifts, 
    HelperConfig _helperConfig,
    uint256 _supplyVouchers
    ) {
      loyaltyPrograms = _loyaltyPrograms;
      loyaltyCards = _loyaltyCards; 
      loyaltyGifts = _loyaltyGifts;
      helperConfig = _helperConfig;
      supplyVouchers = [_supplyVouchers]; 
    }

    // have Program select and mint vouchers 
    // -- needs to result in sufficient amount of selections. 
    function testSelectLoyaltyGiftAndMintVouchers(
      uint256 loyaltyProgramSeed, 
      uint256 giftProgram1Seed,
      uint256 giftProgram2Seed
      ) public {
        LoyaltyProgram loyaltyProgram = _getLoyaltyProgram(loyaltyProgramSeed); 
        LoyaltyGift giftProgram1 = _getGiftProgram(giftProgram1Seed);
        LoyaltyGift giftProgram2 = _getGiftProgram(giftProgram2Seed); 
        // this is all still a bit convoluted
        uint256 amountTokens1 = giftProgram1.getAmountGifts();
        uint256 amountTokens2 = giftProgram2.getAmountGifts();
        uint256[] memory voucherIds = new uint256[](1);

        // select ALL avavialble gifts. 
        vm.startPrank(loyaltyProgram.getOwner()); 
        for (uint256 i; i < amountTokens1; i++) {
           loyaltyProgram.addLoyaltyGift(address(giftProgram1), i); 
        }
        for (uint256 i; i < amountTokens2; i++) {
           loyaltyProgram.addLoyaltyGift(address(giftProgram2), i); 
        }
        vm.stopPrank(); 

        // mint vouchers for ALL available vouchers. 
        for (uint256 i = 0; i < amountTokens1;) {
          if (amountTokens1 == 1) {
            voucherIds[0] = i; 

            vm.prank(loyaltyProgram.getOwner()); 
            loyaltyProgram.mintLoyaltyVouchers(
              address(giftProgram1), 
              voucherIds,  
              supplyVouchers
              ); 
            }
            unchecked { ++i; } 
        }

        for (uint256 i; i < amountTokens2;) {
          if (amountTokens2 == 1) {
            voucherIds[0] = i; 

            vm.prank(loyaltyProgram.getOwner()); 
            loyaltyProgram.mintLoyaltyVouchers(
              address(giftProgram2), 
              voucherIds, 
              supplyVouchers
              ); 
            }

            unchecked { ++i; } 
        } 
      }

    /**
     * @notice loyaltyPrograms transfer points to ANY known card address
     * 
     * @dev the max amount is now set to 5000. Note absent check on amount points program. 
     * @dev This points distributor will try upto 5 cards to see if one is valid. 
     * 
     */
    function testDistributePoints(
      uint256 loyaltyProgramSeed, 
      uint256 loyaltyCardSeed1,
      uint256 loyaltyCardSeed2,
      uint256 loyaltyCardSeed3,
      uint256 loyaltyCardSeed4,
      uint256 loyaltyCardSeed5,
      uint256 amountPointsSeed
      ) public {
      LoyaltyProgram loyaltyProgram = _getLoyaltyProgram(loyaltyProgramSeed);
      address loyaltyCard1 = loyaltyCards[loyaltyCardSeed1 % loyaltyCards.length]; 
      address loyaltyCard2 = loyaltyCards[loyaltyCardSeed2 % loyaltyCards.length]; 
      address loyaltyCard3 = loyaltyCards[loyaltyCardSeed3 % loyaltyCards.length]; 
      address loyaltyCard4 = loyaltyCards[loyaltyCardSeed4 % loyaltyCards.length]; 
      address loyaltyCard5 = loyaltyCards[loyaltyCardSeed5 % loyaltyCards.length]; 
      uint256 amountPoints = amountPointsSeed % 10000 + 5000; 
      address owner = loyaltyProgram.getOwner();

      vm.startPrank(owner); 
      try loyaltyProgram.safeTransferFrom( owner, loyaltyCard1, 0, amountPoints, "" ) { }
        catch { 
      try loyaltyProgram.safeTransferFrom( owner, loyaltyCard2, 0, amountPoints, "" ) { }
        catch { 
      try loyaltyProgram.safeTransferFrom( owner, loyaltyCard3, 0, amountPoints, "" ) { }
        catch { 
      try loyaltyProgram.safeTransferFrom( owner, loyaltyCard4, 0, amountPoints, "" ) { }
        catch {
      try loyaltyProgram.safeTransferFrom( owner, loyaltyCard5, 0, amountPoints, "" ) { }
        catch {
          emit Log("no valid card found this time");
        } 
      }}}}
      vm.stopPrank(); 
    }

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
