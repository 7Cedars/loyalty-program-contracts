// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {RedeemNft} from "../src/RedeemNft.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRedeemNft is Script {

  function run() external returns (RedeemNft) {
    vm.startBroadcast(); 
    RedeemNft redeemNft = new RedeemNft();
    vm.stopBroadcast(); 
    return redeemNft; 
  }
}