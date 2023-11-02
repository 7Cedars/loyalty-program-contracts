// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";


contract DeployLoyaltyProgramTest is Test {
  DeployLoyaltyProgram public deployer; 

  function setUp() public { 
    deployer = new DeployLoyaltyProgram(); 
  }


}