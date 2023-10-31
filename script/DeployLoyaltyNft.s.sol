// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyNft} from "../src/LoyaltyNft.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLoyaltyNft is Script {

  function run() external returns (LoyaltyNft) {
    vm.startBroadcast(); 
    LoyaltyNft loyaltyNft = new LoyaltyNft();
    vm.stopBroadcast(); 
    return loyaltyNft; 
  }
}