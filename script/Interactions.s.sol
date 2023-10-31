// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {RedeemNft} from "../src/RedeemNft.sol";

contract ClaimNft is Script {
  string public constant SHIBA = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json"; 
  address public USER_1 = makeAddr("user1"); 

  function run() external {
    address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
      "RedeemNft",
      block.chainid
    );
    claimNftOnContract(mostRecentlyDeployed); 
  }

  function claimNftOnContract(address contractAddress) public {
    vm.startBroadcast();
    RedeemNft(contractAddress).claimNft(USER_1, SHIBA); 
    vm.stopBroadcast(); 
  } 

}