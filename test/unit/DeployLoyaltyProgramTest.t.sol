// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";

contract DeployLoyaltyProgramTest is Test {
    address public vendorA = makeAddr("vendorA");
    LoyaltyProgram loyaltyProgram; 
    HelperConfig helperConfig; 

    function setUp() public {
        DeployLoyaltyProgram deployer = new DeployLoyaltyProgram();
        (loyaltyProgram, helperConfig) = deployer.run();
    } 
  
    function testDeploymentLoyaltyProgramIsSuccess() public {
      // can insert here more tests 
      assertEq(0, loyaltyProgram.balanceOf(loyaltyProgram.getOwner(), 0));
    }
}
