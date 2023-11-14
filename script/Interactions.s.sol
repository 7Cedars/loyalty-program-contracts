// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {LoyaltyProgram} from "../src/LoyaltyProgram.sol";
import {OneCoffeeFor2500} from "../src/PointsForLoyaltyTokens.sol";

contract InteractionsLoyaltyProgram is Script {
    /* Type declarations */

    address public consumerOne = makeAddr("consumerOne");
    address public consumerTwo = makeAddr("consumerTwo");
    address public consumerThree = makeAddr("consumerThree");
    address public vendorA = makeAddr("vendorA");
    address public vendorB = makeAddr("vendorB");

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FreeCoffeeNft", block.chainid);
        // claimNftOnContract(mostRecentlyDeployed);
    }

    // function claimNftOnContract(address contractAddress) public {

    //   vm.startBroadcast();
    //   OneCoffeeFor2500(contractAddress).requirementsNftMet(consumerOne, 2500);
    //   vm.stopBroadcast();
    // }
}