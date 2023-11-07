// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";


contract DeployLoyaltyProgramTest is Test {
  DeployLoyaltyProgram public deployer; 

  function setUp() public { 
    deployer = new DeployLoyaltyProgram();
  }

  function testDeploymentLoyaltyProgramIsSuccess() public {
    LoyaltyProgram loyaltyProgram = deployer.run();

    // constructor provides 1e25 loyalty points at initialisation. 
    assertEq(1e25, loyaltyProgram.balanceOf(loyaltyProgram.getOwner(), 0)); 
  
  }
}