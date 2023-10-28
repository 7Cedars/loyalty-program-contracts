// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol"; 
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LoyaltyProgramTest is Test {
  LoyaltyProgram loyaltyProgram;
  HelperConfig helperConfig; 
  uint256 initialSupply;  

  address USER_1 = makeAddr("user1"); 
  address USER_2 = makeAddr("user2"); 
  address REDEEM_CONTRACT_A = makeAddr("redeemContractA"); 
  address REDEEM_CONTRACT_B = makeAddr("redeemContractB"); 
  uint256 constant STARTING_BALANCE = 10 ether;  
  uint256 constant GAS_PRICE = 1; 

  modifier usersFunded() {
    uint256 amount1; 
    uint256 amount2; 

    amount1 = bound(amount1, 10, (loyaltyProgram.totalSupply() / 2) ); 
    amount2 = bound(amount2, 10, (loyaltyProgram.totalSupply() / 2) ); 
    
    vm.prank(loyaltyProgram.getOwner());
    loyaltyProgram.transfer(USER_1, amount1); 
    loyaltyProgram.transfer(USER_1, amount2); 

    _; 
  }

  function setUp() external {
    DeployLoyaltyProgram deployer = new DeployLoyaltyProgram(); 
    (loyaltyProgram, helperConfig) = deployer.run(); 
    (initialSupply) = helperConfig.activeNetworkConfig(); 
  }

  function testLoyaltyProgramHasInitialSupply() public {
    assertEq(initialSupply, loyaltyProgram.totalSupply()); //  (ownerContract));  
  }

  function testOwnerCanTransferTokenstoUser_1(uint256 amount) public {
    // Arrange
    uint256 balanceOwnerBefore = loyaltyProgram.balanceOf(loyaltyProgram.getOwner()); 
    uint256 balanceUser1Before = loyaltyProgram.balanceOf(USER_1); 
    amount = bound(amount, 10, loyaltyProgram.totalSupply()); 

    // Act
    vm.prank(loyaltyProgram.getOwner());  
    loyaltyProgram.transfer(USER_1, amount); 

    // Assert 
    uint256 balanceOwnerAfter = loyaltyProgram.balanceOf(loyaltyProgram.getOwner()); 
    uint256 balanceUser1After = loyaltyProgram.balanceOf(USER_1);
    assertEq(loyaltyProgram.balanceOf(USER_1), balanceUser1Before + amount); 
    assertEq(balanceUser1Before + amount, balanceUser1After); 
    assertEq(balanceOwnerBefore - amount, balanceOwnerAfter); 
  }

  function testUserCannotTransferTokenstoOtherUser(uint256 amount) public usersFunded {
    // Arrange
    amount = bound(amount, 10, loyaltyProgram.balanceOf(USER_1)); 

    // Act / Assert
    vm.expectRevert(LoyaltyProgram.LoyaltyProgram__NoAccess.selector);  
    vm.prank(USER_1);
    loyaltyProgram.transfer(USER_2, amount); 
  }

} 