// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyGift} from "../src/mocks/LoyaltyGift.sol";
import {ERC6551Registry} from "../src/mocks/ERC6551Registry.sol";
import {ERC6551BespokeAccount} from "../src/mocks/ERC6551BespokeAccount.sol";
import {IERC6551Account} from "../src/interfaces/IERC6551Account.sol";

contract HelperConfig is Script {
    // these are all the same for networks with deployed ERC6551 - local anvil chain obv does not have one.  

    struct NetworkConfig {
        string uri; 
        uint256 initialSupply; // can differ between chains.
        uint256 interval;
        address erc65511Registry; 
        address payable erc65511Implementation;
        uint32  callbackGasLimit; 
    }
    NetworkConfig public activeNetworkConfig;
    ERC6551Registry public s_erc6551Registry;
    ERC6551BespokeAccount public s_erc6551Implementation;

    /**
     * @notice for now only includes test networks. 
     */
    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } 
        // if (block.chainid == 11155420) {
        //     activeNetworkConfig = getOPSepoliaEthConfig(); // Optimism testnetwork  
        // }
        // if (block.chainid == 421614) {
        //     activeNetworkConfig = getArbitrumSepoliaEthConfig(); // Arbitrum testnetwork  
        // }
        // if (block.chainid == 80001) {
        //     activeNetworkConfig = getMumbaiMaticConfig(); // Polygon testnetwork / POS. See Blueberry and Cardona networks for ZkEvm. 
        // }
        else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // this function can be copied to any network!
    function getSepoliaEthConfig() public returns (NetworkConfig memory) {

        NetworkConfig memory sepoliaConfig = NetworkConfig({
            uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/Qmac3tnopwY6LGfqsDivJwRwEmhMJrCWsx4453JbUyVUnD", 
            initialSupply: 1e25,
            interval: 30, 
            erc65511Registry: 0x000000006551c19487814612e58FE06813775758, // these are all the same for networks with deployed ERC6551 - local anvil chain obv does not have one.  
            erc65511Implementation: payable(0x41C8f39463A868d3A88af00cd0fe7102F30E44eC), 
            callbackGasLimit: 50000 
        });
        return sepoliaConfig;
    }

    // function getOPSepoliaEthConfig() public returns (NetworkConfig memory) {

    //     NetworkConfig memory opSepoliaConfig = NetworkConfig({
    //              FILL OUT LATER - TODO 
    //     });
    //     return opSepoliaConfig;
    // }

    // function getArbitrumSepoliaEthConfig() public returns (NetworkConfig memory) {

    //     NetworkConfig memory arbitrumSepoliaConfig = NetworkConfig({
   //              FILL OUT LATER - TODO 
    //     });
    //     return arbitrumSepoliaConfig;
    // }

    // function getMumbaiMaticConfig() public returns (NetworkConfig memory) {

    //     NetworkConfig memory mumbaiConfig = NetworkConfig({
   //              FILL OUT LATER - TODO 
    //     });
    //     return mumbaiConfig;
    // }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // NB: code for when i need to deploy mock addresses!
        if (activeNetworkConfig.initialSupply != 0x0) { // was address(0)
          return activeNetworkConfig;
        }
        
        vm.startBroadcast();
        s_erc6551Registry = new ERC6551Registry();
        s_erc6551Implementation = new ERC6551BespokeAccount();
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/Qmac3tnopwY6LGfqsDivJwRwEmhMJrCWsx4453JbUyVUnD", 
            initialSupply: 1e25, 
            interval: 30, 
            erc65511Registry: address(s_erc6551Registry),  
            erc65511Implementation: payable(s_erc6551Implementation),  
            callbackGasLimit: 50000
            });

        return anvilConfig;
    }
}
