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
  uint256 minCustomerInteractions; 
  uint256 maxCustomerInteractions; 
  uint256 minPointsPerInteraction; 
  uint256 maxPointsPerInteraction;

  struct Transaction {
    uint256 points;
    uint256 timestamp;
    bool redeemed; 
  }

  address USER_1 = makeAddr("user1"); 
  address USER_2 = makeAddr("user2"); 
  address REDEEM_CONTRACT_A = makeAddr("redeemContractA"); 
  address REDEEM_CONTRACT_B = makeAddr("redeemContractB"); 
  uint256 constant STARTING_BALANCE = 10 ether;  
  uint256 constant GAS_PRICE = 1; 

  modifier usersHaveTransactionHistory() {
    uint256 numberTransactions1; 
    uint256 numberTransactions2;  
    uint256 amount1;
    uint256 amount2; 
    uint256 i; 
    numberTransactions1 = bound(numberTransactions1, 5, 50); 
    numberTransactions2 = bound(numberTransactions2, 10, 25); 
    amount1 = bound(amount1, 20, 750); 
    amount2 = bound(amount2, 10, 1000); 
    
    for (i = 0; i < numberTransactions1; i++) { // for loop in solidity: initialisation, condition, updating. See https://dev.to/shlok2740/loops-in-solidity-2pmp.
      vm.prank(loyaltyProgram.getOwner());
      loyaltyProgram.transfer(USER_1, amount1); 
    }  
    for (i = 0; i < numberTransactions2; i++) {
      vm.prank(loyaltyProgram.getOwner());
      loyaltyProgram.transfer(USER_2, amount1); 
    }
    _; 
  }

  function setUp() external {
    DeployLoyaltyProgram deployer = new DeployLoyaltyProgram(); 
    (loyaltyProgram, helperConfig) = deployer.run(); 
    (
      initialSupply
    ) = helperConfig.activeNetworkConfig(); 
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

  function testUserCannotTransferTokenstoOtherUser(uint256 amount) public usersHaveTransactionHistory() {
    console.log("transactions1: ", loyaltyProgram.getTransactions(USER_1).length);
    console.log("transactions2: ", loyaltyProgram.getTransactions(USER_2).length);
    
    // Arrange
    amount = bound(amount, 0, loyaltyProgram.balanceOf(USER_1)); 

    // Act / Assert
    vm.expectRevert(LoyaltyProgram.LoyaltyProgram__NoAccess.selector);  
    vm.prank(USER_1);
    // vm.prank(loyaltyProgram.getOwner());  
    loyaltyProgram.transfer(USER_2, 10); 
  }

  function testTransactionsAreLogged() public {  
    // Arrange
    uint256 numberTransactions;   
    uint256 amount;
    uint256 i;
    numberTransactions = bound(numberTransactions, 5, 500); 
    amount = bound(amount, 1, 2500); 
    
    // Act
    for (i = 0; i < numberTransactions; i++) {
      vm.prank(loyaltyProgram.getOwner());
      loyaltyProgram.transfer(USER_1, amount); 
    }

    // Assert
    assertEq(numberTransactions, loyaltyProgram.getTransactions(USER_1).length); 
  }

  function testOwnerCanAddRedeemContracts() public {  
    // Act
    vm.prank(loyaltyProgram.getOwner());
    loyaltyProgram.addRedeemContract(REDEEM_CONTRACT_A);

    // Assert
    assertEq(loyaltyProgram.getRedeemContract(REDEEM_CONTRACT_A), true); 
    assertEq(loyaltyProgram.getRedeemContract(address(0)), false); 
  }

  function testOwnerCanRemoveRedeemContracts() public {  
    // Arrange
    vm.prank(loyaltyProgram.getOwner());
    loyaltyProgram.addRedeemContract(REDEEM_CONTRACT_A);
    assertEq(loyaltyProgram.getRedeemContract(REDEEM_CONTRACT_A), true); 
    
    // Act
    vm.prank(loyaltyProgram.getOwner());
    loyaltyProgram.removeRedeemContract(REDEEM_CONTRACT_A);
    
    // Assert
    assertEq(loyaltyProgram.getRedeemContract(REDEEM_CONTRACT_A), false); 
  }

  function testEmitsEventOnRemoveRedeemContract() public {  
    // Arrange
    vm.prank(PLAYER); 
    vm.expectEmit(true, false, false, false, address(raffle)); 
    emit EnteredRaffle(PLAYER); 
    // Act / Assert
    raffle.enterRaffle{value: entranceFee}();


    vm.prank(loyaltyProgram.getOwner());
    loyaltyProgram.addRedeemContract(REDEEM_CONTRACT_A);
    vm.prank(loyaltyProgram.getOwner());
    loyaltyProgram.addRedeemContract(REDEEM_CONTRACT_B);
    
    // Act
    vm.prank(loyaltyProgram.getOwner());
    loyaltyProgram.removeRedeemContract(REDEEM_CONTRACT_A);
    
    // Assert
    assertEq(loyaltyProgram.getRedeemContract(REDEEM_CONTRACT_A), false); 
    assertEq(loyaltyProgram.getRedeemContract(REDEEM_CONTRACT_B), true); 
    assertEq(loyaltyProgram.getRedeemContract(address(0)), false); 
  }


} 