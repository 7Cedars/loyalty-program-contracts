// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// based on: Patrick Collins: helperConfig.s.sol + learning/foundry-fund-me-f23

import {Script, console} from "forge-std/Script.sol";
import {LoyaltyGift} from "../test/mocks/LoyaltyGift.sol";
import {ERC6551Registry} from "../test/mocks/ERC6551Registry.sol";
import {LoyaltyCard6551Account} from "../src/LoyaltyCard6551Account.sol";
import {IERC6551Account} from "../src/interfaces/IERC6551Account.sol";

contract HelperConfig is Script {
    // these are all the same for networks with deployed ERC6551 - local anvil chain obv does not have one.

    struct NetworkConfig {
        uint256 chainid;
        string uri;
        uint256 initialSupply; // can differ between chains.
        uint256 interval;
        address erc6551Registry;
        address payable erc6551Implementation;
        uint32 callbackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;
    ERC6551Registry public s_erc6551Registry;
    LoyaltyCard6551Account public s_erc6551Implementation;

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
        // if (block.chainid == 80001) { // should be base 
        //     activeNetworkConfig = getMumbaiMaticConfig(); // Polygon testnetwork / POS. See Blueberry and Cardona networks for ZkEvm.
        // }
        // if (block.chainid == 80001) { // should be base 
        //     activeNetworkConfig = getMumbaiMaticConfig(); // Polygon testnetwork / POS. See Blueberry and Cardona networks for ZkEvm.
        // }
        else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // this function can be copied to any network!
    function getSepoliaEthConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        s_erc6551Implementation = new LoyaltyCard6551Account();
        vm.stopBroadcast();

        NetworkConfig memory sepoliaConfig = NetworkConfig({
            chainid: 11155111,
            uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/Qmac3tnopwY6LGfqsDivJwRwEmhMJrCWsx4453JbUyVUnD",
            initialSupply: 1e25,
            interval: 30,
            erc6551Registry: 0x02101dfB77FDE026414827Fdc604ddAF224F0921,
            erc6551Implementation: payable(s_erc6551Implementation),
            callbackGasLimit: 50000
        });

        console.logAddress(address(s_erc6551Implementation));

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
        if (activeNetworkConfig.initialSupply != 0x0) {
            // was address(0)
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        s_erc6551Registry = new ERC6551Registry();
        s_erc6551Implementation = new LoyaltyCard6551Account();
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            chainid: 31337,
            uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/Qmac3tnopwY6LGfqsDivJwRwEmhMJrCWsx4453JbUyVUnD",
            initialSupply: 1e25,
            interval: 30,
            erc6551Registry: address(s_erc6551Registry),
            erc6551Implementation: payable(s_erc6551Implementation),
            callbackGasLimit: 50000
        });

        console.logAddress(address(s_erc6551Implementation));

        return anvilConfig;
    }
}
