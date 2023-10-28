// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyAccount} from "../src/LoyaltyAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLoyaltyAccount is Script {
  LoyaltyAccount loyaltyAccount; 

  function run() external returns (LoyaltyAccount, HelperConfig) {
    HelperConfig helperConfig = new HelperConfig();
    (uint256 initialSupply) = helperConfig.activeNetworkConfig(); 

    vm.startBroadcast(); 
      loyaltyAccount = new LoyaltyAccount(initialSupply); 
    vm.stopBroadcast(); 
    return (loyaltyAccount, helperConfig); 
  }
}