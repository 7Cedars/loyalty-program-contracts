// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyNft} from "../src/LoyaltyNft.sol";
import {
  OneCoffeeFor2500, 
  OneCoffeeFor10BuysInWeek, 
  OneCoffeeFor2500And10BuysInWeek
} from "../src/ExampleLoyaltyNfts.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLoyaltyNft is Script {

  function run() external returns (LoyaltyNft) {
    vm.startBroadcast(); 
    LoyaltyNft loyaltyNft = new LoyaltyNft("ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7");
    vm.stopBroadcast(); 
    return loyaltyNft; 
  }  
}

contract DeployOneCoffeeFor2500 is Script {

  function run() external returns (OneCoffeeFor2500) {
    vm.startBroadcast(); 
    OneCoffeeFor2500 oneCoffeeFor2500 = new OneCoffeeFor2500();
    vm.stopBroadcast(); 
    return oneCoffeeFor2500; 
  }  
}

contract DeployOneCoffeeFor10BuysInWeek is Script {

  function run() external returns (OneCoffeeFor10BuysInWeek) {
    vm.startBroadcast(); 
    OneCoffeeFor10BuysInWeek oneCoffeeFor10BuysInWeek = new OneCoffeeFor10BuysInWeek();
    vm.stopBroadcast(); 
    return oneCoffeeFor10BuysInWeek; 
  }  
}

contract DeployOneCoffeeFor2500And10BuysInWeek is Script {

  function run() external returns (OneCoffeeFor2500And10BuysInWeek) {
    vm.startBroadcast(); 
    OneCoffeeFor2500And10BuysInWeek oneCoffeeFor2500And10BuysInWeek = new OneCoffeeFor2500And10BuysInWeek();
    vm.stopBroadcast(); 
    return oneCoffeeFor2500And10BuysInWeek; 
  }  
}