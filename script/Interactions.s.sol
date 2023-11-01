// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {LoyaltyNft} from "../src/LoyaltyNft.sol";
import {OneCoffeeFor2500} from "../src/ExampleLoyaltyNfts.sol";
import {Transaction} from "../src/LoyaltyProgram.sol" ;

contract ClaimNft is Script {
  /* Type declarations */
  
  address public USER_1 = makeAddr("user1"); 
  Transaction[] public transactions;  

  function run() external {
    address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
      "FreeCoffeeNft",
      block.chainid
    );
    claimNftOnContract(mostRecentlyDeployed); 
  }

  function claimNftOnContract(address contractAddress) public {
    
    vm.startBroadcast();
    OneCoffeeFor2500(contractAddress).requirementsNftMet(USER_1, 2500, transactions); 
    vm.stopBroadcast(); 
  } 

}