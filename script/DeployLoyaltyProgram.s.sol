// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyProgram} from "../src/LoyaltyProgram.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLoyaltyProgram is Script {
  LoyaltyProgram loyaltyProgram; 

  function run() external returns (LoyaltyProgram, HelperConfig) {
    HelperConfig helperConfig = new HelperConfig();
    (
      uint256 initialSupply
    ) = helperConfig.activeNetworkConfig(); 

    vm.startBroadcast(); 
      loyaltyProgram = new LoyaltyProgram(
        initialSupply
      ); 
    vm.stopBroadcast(); 
    return (loyaltyProgram, helperConfig); 
  }
}