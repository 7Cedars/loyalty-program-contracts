// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyNft} from "../src/LoyaltyNft.sol";
import {FreeCoffeeNft} from "../src/ExampleLoyaltyNfts.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFreeCoffeeNft is Script {

  function run() external returns (FreeCoffeeNft) {
    vm.startBroadcast(); 
    FreeCoffeeNft freeCoffeeNft = new FreeCoffeeNft();
    vm.stopBroadcast(); 
    return freeCoffeeNft; 
  }

  
}