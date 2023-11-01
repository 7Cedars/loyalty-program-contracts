// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {
  OneCoffeeFor2500
  } from "../../src/ExampleLoyaltyNfts.sol";
import {
  DeployOneCoffeeFor2500
  } from "../../script/DeployLoyaltyNfts.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Transaction} from "../../src/LoyaltyProgram.sol" ;

contract ExampleLoyaltyNftTest is Test {
  DeployOneCoffeeFor2500 public deployer; 

} 
