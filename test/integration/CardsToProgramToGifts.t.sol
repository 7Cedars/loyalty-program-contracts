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
import {SigUtils} from "../utils/SigUtils.sol";

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
  SigUtils sigUtils; 

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

  uint256 customerOneKey = vm.envUint("DEFAULT_ANVIL_KEY_2");
  address customerOneAddress = vm.addr(customerOneKey); 
  uint256 customerTwoKey = vm.envUint("DEFAULT_ANVIL_KEY_3");
  address customerTwoAddress = vm.addr(customerTwoKey); 

  // EIP712 domain separator
  struct EIP712Domain {
      string name;
      string version;
      uint256 chainId;
      address verifyingContract; 
  }

  // RequestGift message struct
  struct RequestGift {
      address from;
      address to;
      string gift;
      string cost;
      uint256 nonce;
  }

  // Redeem token message struct
  struct RedeemVoucher {
      address from;
      address to;
      string voucher;
      uint256 nonce;
  }

  bytes32 internal DOMAIN_SEPARATOR = hashDomain(EIP712Domain({
      name: "Loyalty Program",
      version: "1",
      chainId: block.chainid,
      // Following line fails in testing.. 
      // address(loyaltyProgram) comes up with random / 0 address at this point. Need to hard code address... 
      // is there a solution to this?! 
      verifyingContract: 0xBb2180ebd78ce97360503434eD37fcf4a1Df61c3 
  }));


  ///////////////////////////////////////////////
  ///                   Setup                 ///
  ///////////////////////////////////////////////
  function setUp() external {
    // Deploy Loyalty and Gifts Program 
    DeployLoyaltyProgram deployer = new DeployLoyaltyProgram();
    (loyaltyProgram, helperConfig) = deployer.run();
    DeployMockLoyaltyGifts giftDeployer = new DeployMockLoyaltyGifts(); 
    mockLoyaltyGifts = giftDeployer.run();

    sigUtils = new SigUtils(address(loyaltyProgram)); 

    // an extensive interaction context needed in all tests below. 
    // (hence no modifier used)
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
    for (uint256 i = 0; i < CARD_IDS.length; i++) {
      loyaltyProgram.safeTransferFrom(
        loyaltyProgram.getOwner(),
        loyaltyProgram.getTokenBoundAddress(CARD_IDS[i]), 
        0, 
        POINTS_TO_TRANSFER[i], 
        ""
      ); 
    }
    vm.stopPrank();

    // Transferring one card to customerOne and customerTwo.
    // THIS FAILS on ERC1155MISSINGapproval. 


  //   vm.prank(loyaltyProgram.getOwner());
  //   loyaltyProgram.safeTransferFrom( 
  //     loyaltyProgram.getOwner(), customerTwoAddress, 2, 1, ""
  //   ); 
  }

  ///////////////////////////////////////////////
  ///       Claiming Gifts and Voucher        ///
  ///////////////////////////////////////////////
  
  // Helper function - creating domain seperator    

  
  // Helper function - Hashing domain signature 
  function hashDomain(EIP712Domain memory domain) private pure returns (bytes32) {
      return keccak256(abi.encode(
          keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
          keccak256(bytes(domain.name)),
          keccak256(bytes(domain.version)),
          domain.chainId,
          domain.verifyingContract
      ));
    }

  // Helper function - create customer messages and signature.
  function hashRequestGift(RequestGift memory message) private pure returns (bytes32) {
        return keccak256(abi.encode(
            // keccak256(bytes("RequestGift(uint256 nonce)")),
            keccak256(bytes("RequestGift(address from,address to,string gift,string cost,uint256 nonce)")),
            message.from,
            message.to, 
            keccak256(bytes(message.gift)), 
            keccak256(bytes(message.cost)),
            message.nonce
        ));
    }

  // claiming gift


  // claiming gift reverts 
  function testCustomerCanClaimGift() public {
    uint256 giftId = 3; 
    uint256 loyaltyCardId = 1; 
    
    // loyaltyCard is transferred to customerOne
    vm.startPrank(loyaltyProgram.getOwner());
    loyaltyProgram.safeTransferFrom(
      loyaltyProgram.getOwner(), customerOneAddress, loyaltyCardId, 1, ""
    ); 
    vm.stopPrank(); 

    address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1); 
    // customer creates request
    RequestGift memory message = RequestGift({
      from: loyaltyCardOne, 
      to: address(loyaltyProgram),
      gift: "This is a test gift", 
      cost: "1500 points", 
      nonce: 0
    });

    // customer signs request
    bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message)); 
    console.logBytes32(digest);
   
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
    bytes memory signature = abi.encodePacked(r, s, v);

    // owner of loyaltyprogram uses signature when executing claimLoyaltyGift function. 
    vm.startPrank(loyaltyProgram.getOwner()); 
    loyaltyProgram.claimLoyaltyGift(
      "This is a test gift", // string memory _gift,
      "1500 points", // string memory _cost, 
      address(mockLoyaltyGifts), // address loyaltyGiftsAddress, 
      giftId,  // uint256 loyaltyGiftId, 
      loyaltyCardOne, // address loyaltyCardAddress,
      customerOneAddress,// address customerAddress, 
      2500, // uint256 loyaltyPoints,  
      signature // bytes memory signature
    );
    vm.stopPrank(); 

    assertEq(mockLoyaltyGifts.balanceOf(
      loyaltyProgram.getTokenBoundAddress(loyaltyCardId), giftId
     ), 1); 
  }

    function testClaimGiftRevertsWithInvalidKey() public {
    uint256 giftId = 3; 
    uint256 loyaltyCardId = 1; 
    
    // loyaltyCard is transferred to customerOne
    vm.startPrank(loyaltyProgram.getOwner());
    loyaltyProgram.safeTransferFrom(
      loyaltyProgram.getOwner(), customerOneAddress, loyaltyCardId, 1, ""
    ); 
    vm.stopPrank(); 

    address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1); 
    // customer creates request
    RequestGift memory message = RequestGift({
      from: loyaltyCardOne, 
      to: address(loyaltyProgram),
      gift: "This is a test gift", 
      cost: "1500 points", 
      nonce: 0
    });

    // customer signs request
    bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message)); 
    console.logBytes32(digest);
   
    // Message signed by customerTwo 
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerTwoKey, digest);
    bytes memory signature = abi.encodePacked(r, s, v);

    // owner of loyaltyprogram uses signature when executing claimLoyaltyGift function. 

    vm.expectRevert(
        abi.encodeWithSelector(
          LoyaltyProgram.LoyaltyProgram__RequestInvalid.selector, 
          customerTwoAddress,
          digest
        )
      );

    vm.startPrank(loyaltyProgram.getOwner()); 
    loyaltyProgram.claimLoyaltyGift(
      "This is a test gift", // string memory _gift,
      "1500 points", // string memory _cost, 
      address(mockLoyaltyGifts), // address loyaltyGiftsAddress, 
      giftId,  // uint256 loyaltyGiftId, 
      loyaltyCardOne, // address loyaltyCardAddress,
      customerOneAddress,// address customerAddress, 
      2500, // uint256 loyaltyPoints,  
      signature // bytes memory signature
    );
    vm.stopPrank(); 
  }



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


// NB: docs on console.logging:  https://book.getfoundry.sh/reference/forge-std/console-log?highlight=console.loguint#console-logging

//     function testCustomerCannotMintLoyaltyPoints(uint256 amount) public {
//         amount = bound(amount, 10, 1e20);

//         // Act
//         vm.expectRevert(LoyaltyProgram.LoyaltyProgram__OnlyOwner.selector);
//         vm.prank(customerOne);
//         loyaltyProgramA.mintLoyaltyPoints(amount);
//     }

// HERE TEST CLAIM GIFT AND REDEEM TOKEN . 