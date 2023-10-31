// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {LoyaltyNft} from "../src/LoyaltyNft.sol";
import {FreeCoffeeNft} from "../src/FreeCoffeeNft.sol";

contract ClaimNft is Script {
  address public USER_1 = makeAddr("user1"); 

  function run() external {
    address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
      "FreeCoffeeNft",
      block.chainid
    );
    claimNftOnContract(mostRecentlyDeployed); 
  }

  function claimNftOnContract(address contractAddress) public {
    vm.startBroadcast();
    FreeCoffeeNft(contractAddress).claimNft(USER_1, 2500); 
    vm.stopBroadcast(); 
  } 

}