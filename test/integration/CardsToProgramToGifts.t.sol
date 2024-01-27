// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {MockLoyaltyGifts} from "../../src/mocks/MockLoyaltyGifts.sol";  
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {DeployMockLoyaltyGifts} from "../../script/DeployLoyaltyGifts.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC6551Registry} from "../../src/mocks/ERC6551Registry.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SigUtilRequestGift} from "../utils/SigUtilRequestGift.sol";

contract CardsToProgramToGiftsTest is Test {
  /* events */
  event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
  event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

  /* Type declarations */
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;

  LoyaltyProgram loyaltyProgram;
  MockLoyaltyGifts mockLoyaltyGifts; 
  HelperConfig helperConfig; 
  SigUtilRequestGift sigUtilRequestGift; 

  uint256[] GIFTS_TO_SELECT = [0, 3, 5];
  uint256[] VOUCHERS_TO_MINT = [3, 5]; 
  uint256[] AMOUNT_VOUCHERS_TO_MINT = [24, 45]; 
  uint256[] GIFTS_TO_DESELECT = [3];
  uint256 CARDS_TO_MINT = 3; 
  uint256[] CARD_IDS = [1,2,3]; 
  uint256[] CARDS_SINGLES = [1,1,1];
  uint256 POINTS_TO_MINT = 500000000; 
  uint256[] POINTS_TO_TRANSFER = [10000, 12000, 14000]; 
  uint256 SALT_TOKEN_BASED_ACCOUNT = 3947539732098357; 
  uint256 NONCE = 1; 

  uint256 customerOneKey = vm.envUint("DEFAULT_ANVIL_KEY_1");
  address customerOneAddress = vm.addr(customerOneKey); 
  uint256 customerTwoKey = vm.envUint("DEFAULT_ANVIL_KEY_2");
  address customerTwoAddress = vm.addr(customerTwoKey); 

  // Interactive conetxt needed to test claim and redeem functions. 
  modifier withInteractiveContext() 
    {
    vm.startPrank(loyaltyProgram.getOwner());
    
    // Loyalty Program selecting Gifts
    for (uint256 i = 0; i < GIFTS_TO_SELECT.length; i++) {
      loyaltyProgram.addLoyaltyGift(
        address(mockLoyaltyGifts),
        GIFTS_TO_SELECT[i]
      ); 
    }

    // Loyalty Program minting Loyalty Points, Cards and Vouchers
    loyaltyProgram.mintLoyaltyPoints(POINTS_TO_MINT); 
    loyaltyProgram.mintLoyaltyCards(CARDS_TO_MINT); 
    loyaltyProgram.mintLoyaltyVouchers(
        address(mockLoyaltyGifts), 
        VOUCHERS_TO_MINT, 
        AMOUNT_VOUCHERS_TO_MINT
      ); 
    
    // Loyalty Program Transferring Points to Cards
    for (uint256 i = 0; i < GIFTS_TO_SELECT.length; i++) {
      loyaltyProgram.safeTransferFrom(
        address(mockLoyaltyGifts),
        loyaltyProgram.getTokenBoundAddress(CARD_IDS[i]), 
        0, 
        POINTS_TO_TRANSFER[i], 
        ""
      ); 
    }

    // Transferring one card to customerOne and customerTwo.
    loyaltyProgram.safeTransferFrom(
      address(loyaltyProgram), customerOneAddress, 1, 1, ""
    ); 

    loyaltyProgram.safeTransferFrom( 
      address(loyaltyProgram), customerOneAddress, 2, 1, ""
    ); 

    vm.stopPrank();
    
    _;
  }

  ///////////////////////////////////////////////
  ///                   Setup                 ///
  ///////////////////////////////////////////////
  function setUp() external {
    // Deploy Loyalty and Gifts Program 
    DeployLoyaltyProgram deployer = new DeployLoyaltyProgram();
    (loyaltyProgram, helperConfig) = deployer.run();
    DeployMockLoyaltyGifts giftDeployer = new DeployMockLoyaltyGifts(); 
    mockLoyaltyGifts = giftDeployer.run();

    sigUtilRequestGift = new SigUtilRequestGift()
  }

  ///////////////////////////////////////////////
  ///       Claiming Gifts and Voucher        ///
  ///////////////////////////////////////////////

  // // Helper function - create customer messages and signature.
  // function createSignatureAndMessage(
  //   uint256 customerKey, 
  //   address customerAddress, 
  //   address loyaltyGiftsAddress, 
  //   uint256 loyaltyGiftId, 
  //   uint256 loyaltyPoints
  // ) public returns (
  //   string memory _gift,
  //   string memory _cost,
  //   bytes memory signature
  //   ) { 
      


  //   }  


  // claiming gift
  function testCustomerCanClaimGift(uint256 amount) public {


  }

  // claiming gift reverts 


  // claiming gift Event emit

  
  // claiming voucher 


  // claiming voucher event emits. 


  ///////////////////////////////////////////////
  ///               Redeemt Voucher           /// 
  ///////////////////////////////////////////////

  // Helper function - create customer messages and signature.


  // redeeming voucher success. 


  // redeeming voucher reverts. 


  // redeeming voucher event emits. 




} 




//     function testCustomerCannotMintLoyaltyPoints(uint256 amount) public {
//         amount = bound(amount, 10, 1e20);

//         // Act
//         vm.expectRevert(LoyaltyProgram.LoyaltyProgram__OnlyOwner.selector);
//         vm.prank(customerOne);
//         loyaltyProgramA.mintLoyaltyPoints(amount);
//     }

// HERE TEST CLAIM GIFT AND REDEEM TOKEN . 