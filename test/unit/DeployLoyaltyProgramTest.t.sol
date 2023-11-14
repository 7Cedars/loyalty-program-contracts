// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";

contract DeployLoyaltyProgramTest is Test {
    DeployLoyaltyProgram public deployer;
    address public vendorA = makeAddr("vendorA");

    function setUp() public {
        deployer = new DeployLoyaltyProgram();
    }

    function testDeploymentLoyaltyProgramIsSuccess() public {
        LoyaltyProgram loyaltyProgram = deployer.run();

        // constructor provides 0 loyalty points at initialisation.
        // Should implement different check maybe in the future.
        // assertEq(0, loyaltyProgram.balanceOf(loyaltyProgram.getOwner(), 0));
    }
}
