// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol"; 
import {LoyaltyAccount} from "../src/LoyaltyAccount.sol";
import {DeployLoyaltyAccount} from "../script/DeployLoyaltyAccount.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract LoyaltyAccountTest is Test {
  LoyaltyAccount loyaltyAccount;
  HelperConfig helperConfig; 

  uint256 initialSupply;  

  address USER = makeAddr("user"); 
  uint256 constant STARTING_BALANCE = 10 ether;  
  uint256 constant GAS_PRICE = 1; 

  function setUp() external {
    DeployLoyaltyAccount deployer = new DeployLoyaltyAccount(); 
    (loyaltyAccount, helperConfig) = deployer.run(); 
    (initialSupply) = helperConfig.activeNetworkConfig(); 
  }

  function testLoyaltyAccountHasInitialSupply() public {
    assertEq(initialSupply, loyaltyAccount.totalSupply()); //  (ownerContract));  
  }


} 