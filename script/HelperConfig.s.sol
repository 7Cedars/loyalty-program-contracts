// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyGift} from "../src/LoyaltyGift.sol";

contract HelperConfig is Script {
    uint256[] public TOKENISED = [0, 0, 0, 1, 1, 1]; // 0 == false, 1 == true.  
    string public URI = "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmX5em6Dh4XgnZ6pe4igkZqkf6mSRTRbNja2w3qE8qcfGT"; 

    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        uint256 initialSupply; // can differ between chains.
        LoyaltyGift loyaltyGiftsContract; 
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // this function can be copied to any network!
    function getSepoliaEthConfig() public returns (NetworkConfig memory) {
        // This should be: find last deployed - I think. 
        vm.startBroadcast();
        LoyaltyGift loyaltyGiftsContract = new LoyaltyGift(URI, TOKENISED);
        vm.stopBroadcast();

        NetworkConfig memory sepoliaConfig = NetworkConfig({
            initialSupply: 1e25, 
            loyaltyGiftsContract: loyaltyGiftsContract
            });
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // NB: code for when i need to deploy mock addresses!
        if (activeNetworkConfig.initialSupply != 0x0) { // was address(0)
          return activeNetworkConfig;
        }
        //
        vm.startBroadcast();
        LoyaltyGift loyaltyGiftsContract = new LoyaltyGift(URI, TOKENISED);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            initialSupply: 1e25, 
            loyaltyGiftsContract: loyaltyGiftsContract
            });

        return anvilConfig;
    }
}
