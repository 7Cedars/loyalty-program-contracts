// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyProgram} from "../src/LoyaltyProgram.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLoyaltyProgram is Script {
  LoyaltyProgram loyaltyProgram; 

  // NB: If I need a helper config, see helperConfig.s.sol + learning/foundry-fund-me-f23
  function run() external returns (LoyaltyProgram) { 
    vm.startBroadcast(); 
      loyaltyProgram = new LoyaltyProgram( ); 
    vm.stopBroadcast(); 
    return (loyaltyProgram);
  }
}