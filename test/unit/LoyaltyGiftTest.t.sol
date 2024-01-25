// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {LoyaltyGift} from "../../src/mocks/LoyaltyGift.sol";
import { DeployLoyaltyGift } from "../../script/DeployLoyaltyGifts.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";


contract LoyaltyGiftTest is Test {

  ///////////////////////////////////////////////
  ///                   Setup                 ///
  ///////////////////////////////////////////////

  LoyaltyGift loyaltyGift; 

  function setUp() external {
    DeployLoyaltyGift deployer = new DeployLoyaltyGift();
    loyaltyGift = deployer.run();
  }

  function testLoyaltyGiftHasTokenised() public {
    uint256[] memory tokenised = loyaltyGift.getTokenised(); 
    assertNotEq(tokenised.length, 0);
  }

  function testRequirementsReturnsTrue() public {
    bool result = loyaltyGift.requirementsLoyaltyGiftMet(address(0), 0, 0); 
    assertEq(result, true);
  }

  ///////////////////////////////////////////////
  ///        Minting token / vouchers         ///
  ///////////////////////////////////////////////





  ///////////////////////////////////////////////
  ///            Issuing gifts                ///
  ///////////////////////////////////////////////
  function testReturnsTrueForNonTokenisedGift() public {
    bool result = loyaltyGift.issueLoyaltyGift(address(0), 0, 0); 

    assertEq(result, true);
  }

  function testRevertsForNonAvailableTokenisedGift() public {
    vm.expectRevert(
       abi.encodeWithSelector(
        LoyaltyGift.LoyaltyGift__NoTokensAvailable.selector, 
        address(loyaltyGift)
        )
    );
    loyaltyGift.issueLoyaltyGift(address(0), 1, 0);

  }


  ///////////////////////////////////////////////
  ///    Reclaiming Tokens (vouchers)         ///
  ///////////////////////////////////////////////

  


}