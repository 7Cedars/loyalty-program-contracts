// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol"; 
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LoyaltyProgramTest is Test {

  /* events */ 
  event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
  event AddedLoyaltyNft(address indexed loyaltyNft);  
  event RemovedLoyaltyNft(address indexed loyaltyNft);

  ///////////////////////////////////////////////
  ///                   Setup                 ///
  ///////////////////////////////////////////////

  LoyaltyProgram loyaltyProgram;
  HelperConfig helperConfig; 
  uint256 minCustomerInteractions; 
  uint256 maxCustomerInteractions; 
  uint256 minPointsPerInteraction; 
  uint256 maxPointsPerInteraction;

  struct Transaction {
    uint256 points;
    uint256 timestamp;
    bool redeemed; 
  }

  address public userOne = makeAddr("user1"); 
  address public userTwo = makeAddr("user2"); 
  address public redeemContractA = makeAddr("loyaltyNftA"); 
  address public redeemContractB = makeAddr("loyaltyNftB"); 
  uint256 constant STARTING_BALANCE = 10 ether;  
  uint256 constant GAS_PRICE = 1; 

  modifier usersHaveLoyaltyPoints(
    ) {
      uint256 numberTransactions1;
      uint256 numberTransactions2; 
      uint256 amount1;
      uint256 amount2; 
      uint256 i;
      amount1 = bound(amount1, 20, 750); 
      amount2 = bound(amount2, 10, 1000);
      address ownerProgram = loyaltyProgram.getOwner(); 
    
      vm.prank(loyaltyProgram.getOwner());
      loyaltyProgram.safeTransferFrom(loyaltyProgram.getOwner(), userOne, 0, amount1, ""); 
      vm.prank(loyaltyProgram.getOwner());
      loyaltyProgram.safeTransferFrom(loyaltyProgram.getOwner(), userTwo, 0, amount2, "");
    _;
  }

  function setUp() external {
    DeployLoyaltyProgram deployer = new DeployLoyaltyProgram(); 
    loyaltyProgram = deployer.run(); 
  }

  function testLoyaltyProgramHasInitialSupply() public {
    assertEq(1e25, loyaltyProgram.balanceOf(loyaltyProgram.getOwner(), 0));
    assertEq(1, loyaltyProgram.balanceOf(loyaltyProgram.getOwner(), 1)); 
    assertEq(1, loyaltyProgram.balanceOf(loyaltyProgram.getOwner(), 24));  
  }

  ///////////////////////////////////////////////
  ///   Test Mint and Transfer LoyaltyCards   ///
  ///////////////////////////////////////////////

  function testOwnerCanMintLoyaltyCards(uint256 numberToMint) public { 
    uint256 totalSupplyBefore; 
    uint256 totalSupplyAfter; 
    uint256 totalLoyaltyCardsMinted; 
    uint i; 

    numberToMint = bound(numberToMint, 1, 5);
    totalLoyaltyCardsMinted = loyaltyProgram.getNumberLoyaltyCardsMinted(); 
    
    for (i = 1; i < totalLoyaltyCardsMinted; i++) {
      totalSupplyBefore = totalSupplyBefore + loyaltyProgram.balanceOf(loyaltyProgram.getOwner(), i); 
    }

    // Act
    vm.prank(loyaltyProgram.getOwner());  
    loyaltyProgram.mintLoyaltyCards(numberToMint); 

    totalLoyaltyCardsMinted = loyaltyProgram.getNumberLoyaltyCardsMinted(); 
    for (i = 1; i < totalLoyaltyCardsMinted; i++) {
      totalSupplyAfter = totalSupplyAfter + loyaltyProgram.balanceOf(loyaltyProgram.getOwner(), i); 
    }

    // Assert 
    assertEq(totalSupplyBefore + numberToMint, totalSupplyAfter); 
  }

  function testOwnerCanTransferLoyaltyCards(uint256 numberToMint) public { 
    uint i;
    uint256 numberLoyaltyCards; 

    numberToMint = bound(numberToMint, 10, 50);
    vm.prank(loyaltyProgram.getOwner());  
    loyaltyProgram.mintLoyaltyCards(numberToMint);

    for (i = 1; i <= numberToMint; i++) {
      vm.prank(loyaltyProgram.getOwner());  
      loyaltyProgram.safeTransferFrom(loyaltyProgram.getOwner(), userOne, i, 1, ""); 
    }

    for (i = 1; i <= numberToMint; i++) {
      numberLoyaltyCards = numberLoyaltyCards + loyaltyProgram.balanceOf(userOne, i); 
    }

    // Assert 
    assertEq(numberToMint, numberLoyaltyCards); 
  }
  
  //////////////////////////////////////////////////////
  ///     Test Mint, Gift, Transfer LoyaltyPoints    ///
  //////////////////////////////////////////////////////


  function testOwnerCanMintLoyaltyPoints(uint256 amount) public { 
    uint256 totalSupplyBefore; 
    uint256 totalSupplyAfter; 

    amount = bound(amount, 10, 1e20);
    totalSupplyBefore = loyaltyProgram.balanceOf(loyaltyProgram.getOwner(), 0); 

    // Act
    vm.prank(loyaltyProgram.getOwner());  
    loyaltyProgram.mintLoyaltyPoints(amount); 
    totalSupplyAfter = loyaltyProgram.balanceOf(loyaltyProgram.getOwner(), 0); 

    // Assert 
    assertEq(totalSupplyBefore + amount, totalSupplyAfter); 
  }

  function testUserCannotMintLoyaltyPoints(uint256 amount) public { 
    amount = bound(amount, 10, 1e20);

    // Act
    vm.expectRevert(LoyaltyProgram.LoyaltyProgram__OnlyOwner.selector);  
    vm.prank(userOne); 
    loyaltyProgram.mintLoyaltyPoints(amount);
  }

  // function testLoyaltyPointsCanBeTransferred(uint256 amount) public { 
  //   numberOfLoyaltyPoints = bound(amount, 10, 1e20);
  //   singleLoyaltyCard = 
  //   mintLoyaltyCards

    
  //   vm.prank(loyaltyProgram.getOwner());

  //   loyaltyProgram.giftLoyaltyPoints(userOne, amount);
  //   assertEq(loyaltyProgram.balanceOf(userOne, 0), amount);

  //   vm.prank(userOne);
  //   loyaltyProgram.safeTransferFrom(userOne, userTwo, 0, 5, "");
  //   assertEq(loyaltyProgram.balanceOf(userTwo, 0), 5);

  // }


 

  /////////////////////////////////////////////////////
  /// Test Adding, Removing Loyalty Token Contracts ///
  /////////////////////////////////////////////////////

  // function testOwnerCanAddLoyaltyNfts() public {  
  //   // Act
  //   vm.prank(loyaltyProgram.getOwner());
  //   loyaltyProgram.addLoyaltyNft(redeemContractA);
  //   console.log("redeemContractA: ", redeemContractA); 

  //   // Assert
  //   assertEq(loyaltyProgram.getLoyaltyNft(redeemContractA), true); 
  //   assertEq(loyaltyProgram.getLoyaltyNft(address(0)), false); 
  // }

  // function testEmitsEventOnAddingloyaltyNft() public {  
  //   // Arrange
  //   vm.expectEmit(true, false, false, false, address(loyaltyProgram)); 
  //   emit AddedLoyaltyNft(redeemContractA);
  //   // Act / Assert
  //   vm.prank(loyaltyProgram.getOwner());
  //   loyaltyProgram.addLoyaltyNft(redeemContractA);
  // }

  // function testOwnerCanRemoveLoyaltyNfts() public {  
  //   // Arrange
  //   vm.prank(loyaltyProgram.getOwner());
  //   loyaltyProgram.addLoyaltyNft(redeemContractA);
  //   assertEq(loyaltyProgram.getLoyaltyNft(redeemContractA), true); 
    
  //   // Act
  //   vm.prank(loyaltyProgram.getOwner());
  //   loyaltyProgram.removeLoyaltyNft(redeemContractA);
    
  //   // Assert
  //   assertEq(loyaltyProgram.getLoyaltyNft(redeemContractA), false); 
  // }

  // function testEmitsEventOnRemovingloyaltyNft() public {  
  //   // Arrange
  //   vm.expectEmit(true, false, false, false, address(loyaltyProgram)); 
  //   emit RemovedLoyaltyNft(redeemContractA);
  //   // Act / Assert
  //   vm.prank(loyaltyProgram.getOwner());
  //   loyaltyProgram.removeLoyaltyNft(redeemContractA);
  // }

  // function testUserCannotAddLoyaltyNfts() public {  
  //   vm.expectRevert(LoyaltyProgram.LoyaltyProgram__OnlyOwner.selector);
  //   vm.prank(userOne);
  //   loyaltyProgram.addLoyaltyNft(redeemContractA);
  // }

  // function testUserCannotRemoveLoyaltyNfts() public {  
  //   vm.expectRevert(LoyaltyProgram.LoyaltyProgram__OnlyOwner.selector);
  //   vm.prank(userOne);
  //   loyaltyProgram.addLoyaltyNft(redeemContractA);
  // }



  //   vm.prank(loyaltyProgram.getOwner());
  //   loyaltyProgram.addLoyaltyNft(redeemContractA);
  //   vm.prank(loyaltyProgram.getOwner());
  //   loyaltyProgram.addLoyaltyNft(redeemContractB);
    
  //   // Act
  //   vm.prank(loyaltyProgram.getOwner());
  //   loyaltyProgram.removeLoyaltyNft(redeemContractA);
    
  //   // Assert
  //   assertEq(loyaltyProgram.getoyaltyNft(redeemContractA), false); 
  //   assertEq(loyaltyProgram.getoyaltyNft(redeemContractB), true); 
  //   assertEq(loyaltyProgram.getoyaltyNft(address(0)), false); 
  // }




  /////////////////////////////////////////////////////////
  /// Test Minting, Claiming, Redeeeming Loyalty Tokens ///
  ///////////////////////////////////////////////////////// 


  // function testOwnerCanTransferTokenstouserOne(uint256 amount) public {
  //   // Arrange
  //   uint256 balanceOwnerBefore = loyaltyProgram.balanceOf(loyaltyProgram.getOwner()); 
  //   uint256 balanceUser1Before = loyaltyProgram.balanceOf(userOne); 
  //   amount = bound(amount, 10, loyaltyProgram.totalSupply()); 

  //   // Act
  //   vm.prank(loyaltyProgram.getOwner());  
  //   loyaltyProgram.transfer(userOne, amount); 

  //   // Assert 
  //   uint256 balanceOwnerAfter = loyaltyProgram.balanceOf(loyaltyProgram.getOwner()); 
  //   uint256 balanceUser1After = loyaltyProgram.balanceOf(userOne);
  //   assertEq(loyaltyProgram.balanceOf(userOne), balanceUser1Before + amount); 
  //   assertEq(balanceUser1Before + amount, balanceUser1After); 
  //   assertEq(balanceOwnerBefore - amount, balanceOwnerAfter); 
  // }

  // function testEmitsEventOnTransferTokens(uint256 amount) public {  
  //   // Arrange
  //   // use vm.recordLogs(); ? 
  //   // after action 
  //   // vm.Log[] memory entries = vm.getRecordLogs(); 
    
  //   amount = bound(amount, 15, 2500); 
  //   vm.expectEmit(true, false, false, false, address(loyaltyProgram)); 
  //   emit Transfer(loyaltyProgram.getOwner(), userOne, amount);

  //   // Act / Assert
  //   vm.prank(loyaltyProgram.getOwner());
  //   loyaltyProgram.transfer(userOne, amount);
  // }  


  // function testUserCannotTransferTokenstoOtherUser(uint256 amount) public usersHaveTransactionHistory() {
  //   // Arrange
  //   amount = bound(amount, 0, loyaltyProgram.balanceOf(userOne)); 
  //   // Act / Assert
  //   vm.expectRevert(LoyaltyProgram.LoyaltyProgram__NoAccess.selector);  
  //   vm.prank(userOne);
  //   // vm.prank(loyaltyProgram.getOwner());  
  //   loyaltyProgram.transfer(userTwo, 10); 
  // }


} 