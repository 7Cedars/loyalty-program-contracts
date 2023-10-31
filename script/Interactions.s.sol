// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {LoyaltyNft} from "../src/LoyaltyNft.sol";

contract ClaimNft is Script {
  address public USER_1 = makeAddr("user1"); 

  function run() external {
    address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
      "LoyaltyNft",
      block.chainid
    );
    claimNftOnContract(mostRecentlyDeployed); 
  }

  function claimNftOnContract(address contractAddress) public {
    vm.startBroadcast();
    LoyaltyNft(contractAddress).claimNft(USER_1); 
    vm.stopBroadcast(); 
  } 

}