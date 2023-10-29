// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
  NetworkConfig public activeNetworkConfig;
  uint8 public constant DECIMALS = 8;
  int256 public constant INITIAL_PRICE = 2000e8; 

  struct NetworkConfig {
    uint256 initialSupply; // can differ between chains. 
  }

  constructor() {
    if (block.chainid == 11155111) {
      activeNetworkConfig = getSepoliaEthConfig(); 
    } else {
      activeNetworkConfig = getOrCreateAnvilEthConfig(); 
    }
  } 

  // this function can be copied to any network! 
  function getSepoliaEthConfig() public pure returns (NetworkConfig memory) { 
    // price feed address
    NetworkConfig memory sepoliaConfig = NetworkConfig({
      initialSupply: 1e15
    });
    return sepoliaConfig;
  }

function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) { 
    
    // NB: code for when i need to deploy mock addresses! 
    // if (activeNetworkConfig.initialSupply != address(0)) {
    //   return activeNetworkConfig;
    // }
    // 
    // vm.startBroadcast(); 
    // MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
    // vm.stopBroadcast(); 

    NetworkConfig memory anvilConfig = NetworkConfig({
      initialSupply: 1e15
    });

    return anvilConfig; 
  }

}