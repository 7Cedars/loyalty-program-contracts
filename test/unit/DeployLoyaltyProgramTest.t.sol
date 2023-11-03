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

    string memory expectedName = "LoyaltyPoints"; 
    string memory actualName = loyaltyProgram.name(); 
    // NB you cannot just compare strings! 
    assert(
      keccak256(abi.encodePacked(expectedName))
      ==
      keccak256(abi.encodePacked(actualName))
      ); 
  }
}