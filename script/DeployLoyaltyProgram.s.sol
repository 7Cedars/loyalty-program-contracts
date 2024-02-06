// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyProgram} from "../src/LoyaltyProgram.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {MockLoyaltyGifts} from "../test/mocks/MockLoyaltyGifts.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract DeployLoyaltyProgram is Script {
    LoyaltyProgram loyaltyProgram;

    // NB: If I need a helper config, see helperConfig.s.sol + learning/foundry-fund-me-f23
    function run() external returns (LoyaltyProgram, HelperConfig) {
       HelperConfig helperConfig = new HelperConfig(); 

        ( , 
          string memory uri,
          ,
          ,
          address erc65511Registry, 
          address erc65511Implementation, 

        ) = helperConfig.activeNetworkConfig();  

      vm.startBroadcast();
      loyaltyProgram = new LoyaltyProgram(
        uri, 
        erc65511Registry,
        payable(erc65511Implementation)
        );
      vm.stopBroadcast();

      return (loyaltyProgram, helperConfig);
    }    
}
