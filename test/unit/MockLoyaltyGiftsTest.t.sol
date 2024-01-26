// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {MockLoyaltyGifts} from "../../src/mocks/MockLoyaltyGifts.sol";
import {ILoyaltyGift} from "../../src/interfaces/ILoyaltyGift.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployMockLoyaltyGifts} from "../../script/DeployLoyaltyGifts.s.sol";

// ///////////////////////////////////////////////
// ///                   Setup                 ///
// ///////////////////////////////////////////////

contract MockLoyaltyGiftsTest is Test {
    /** events */
  event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
  event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
  event LoyaltyGiftDeployed(address indexed issuer, uint256[] tokenised);

  uint256 keyZero = vm.envUint("DEFAULT_ANVIL_KEY_0");
  address addressZero = vm.addr(keyZero); 
  uint256 keyOne = vm.envUint("DEFAULT_ANVIL_KEY_1");
  address addressOne = vm.addr(keyOne); 

  string GIFT_URI = "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmSshfobzx5jtA14xd7zJ1PtmG8xFaPkAq2DZQagiAkSET/{id}"; 
  uint256[] TOKENISED = [0, 0, 0, 1, 1, 1]; 
  uint256[] VOUCHERS_TO_MINT = [1]; 
  uint256[] AMOUNT_VOUCHERS_TO_MINT = [24]; 
  uint256[] NON_TOKENISED_TO_MINT = [0]; 
  uint256[] AMOUNT_NON_TOKENISED_TO_MINT = [1]; 
  uint256[] GIFT_PRICES = [2500, 4500, 50000, 2500, 4500, 50000];

  ///////////////////////////////////////////////
  ///                   Setup                 ///
  ///////////////////////////////////////////////

  MockLoyaltyGifts mockLoyaltyGifts;

  function setUp() external {
    DeployMockLoyaltyGifts deployer = new DeployMockLoyaltyGifts();
    mockLoyaltyGifts = deployer.run();
  }

  function testLoyaltyGiftHasTokenised() public {
    uint256[] memory tokenised = mockLoyaltyGifts.getTokenised(); 
    assertEq(tokenised, TOKENISED);
  }
  
  function testDeployEmitsevent() public {
    vm.expectEmit(true, false, false, false);
    emit LoyaltyGiftDeployed(
      addressZero,
      TOKENISED);

    vm.prank(addressZero);
    mockLoyaltyGifts = new MockLoyaltyGifts();
  }

  /////////////////////////////////////////////////////////
  ///          Test Different Requirement Test          /// 
  /////////////////////////////////////////////////////////

  function testRequirementsReturnTrueWhenMet() public {
    for (uint256 i = 0; i < GIFT_PRICES.length; i++) {
      bool success;  
      
      (success) = mockLoyaltyGifts.requirementsLoyaltyGiftMet(addressOne, i, GIFT_PRICES[i]);  
      assertEq(success, true);
    }
  }

  function testRequirementsRevertsWhenNotMet() public {
    for (uint256 i = 0; i < GIFT_PRICES.length; i++) {
      vm.expectRevert(
        abi.encodeWithSelector(
          ILoyaltyGift.LoyaltyGift__RequirementsNotMet.selector, 
          address(mockLoyaltyGifts),
          i
        )
      );
      
      mockLoyaltyGifts.requirementsLoyaltyGiftMet(addressOne, i, GIFT_PRICES[i] - 1);  
    }
  }
      
}
