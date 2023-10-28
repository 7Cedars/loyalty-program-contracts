// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

contract HelperConfig is Script {
  NetworkConfig public activeNetworkConfig;
  uint8 public constant DECIMALS = 8;
  int256 public constant INITIAL_PRICE = 2000e8; 

  struct NetworkConfig {
    address priceFeed; // ETH/USD
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
      priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306, 
      initialSupply: 10000
    });
    return sepoliaConfig;
  }

function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) { 
    if (activeNetworkConfig.priceFeed != address(0)) {
      return activeNetworkConfig;
    }

    vm.startBroadcast(); 
    MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
    vm.stopBroadcast(); 

    NetworkConfig memory anvilConfig = NetworkConfig({
      priceFeed: address(mockPriceFeed), 
      initialSupply: 10000
    });

    return anvilConfig; 
  }

}