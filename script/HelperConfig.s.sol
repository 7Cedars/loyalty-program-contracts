// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// // based on: Patrick Collins: helperConfig.s.sol + learning/foundry-fund-me-f23

// import {Script, console} from "forge-std/Script.sol";
// import {MockLoyaltyGift} from "../test/mocks/MockLoyaltyGift.sol";
// import {ERC6551Registry} from "../test/mocks/ERC6551Registry.t.sol";
// import {LoyaltyCard6551Account} from "../src/LoyaltyCard6551Account.sol";

// contract HelperConfig is Script {
//     // these are all the same for networks with deployed ERC6551 - local anvil chain obv does not have one.

//     struct NetworkConfig {
//         uint256 chainid;
//         string uri;
//         uint256 initialSupply; // can differ between chains.
//         uint256 interval;
//         address erc6551Registry;
//         address payable erc6551Implementation;
//         uint32 callbackGasLimit;
//     }

//     NetworkConfig public activeNetworkConfig;
//     ERC6551Registry public s_erc6551Registry;
//     LoyaltyCard6551Account public s_erc6551Implementation;
//     bytes32 public SALT = 0x0000000000000000000000000000000000000000000000000000000007ceda52; 

//     /**
//      * @notice for now only includes test networks.
//      */
//     constructor() {
//         if (block.chainid == 11155111) {
//             activeNetworkConfig = getSepoliaEthConfig();
//         }
//         if (block.chainid == 11155420) {
//             activeNetworkConfig = getOPSepoliaEthConfig(); // Optimism testnetwork
//         }
//         if (block.chainid == 421614) {
//             activeNetworkConfig = getArbitrumSepoliaEthConfig(); // Arbitrum testnetwork
//         }
//         if (block.chainid == 84532) { // should be base 
//             activeNetworkConfig = getBaseSepoliaConfig(); // Polygon testnetwork / POS. See Blueberry and Cardona networks for ZkEvm.
//         }
//         if (block.chainid == 80001) { // should be base 
//             activeNetworkConfig = getMumbaiMaticConfig(); // Polygon testnetwork / POS. See Blueberry and Cardona networks for ZkEvm.
//         }
//         else {
//             activeNetworkConfig = getOrCreateAnvilEthConfig();
//         }
//     }

//     // this function can be copied to any network!
//     function getSepoliaEthConfig() public returns (NetworkConfig memory) {
//         vm.startBroadcast();
//         s_erc6551Implementation = new LoyaltyCard6551Account{salt: SALT}();
//         vm.stopBroadcast();

//         NetworkConfig memory sepoliaConfig = NetworkConfig({
//             chainid: 11155111,
//             uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/Qmac3tnopwY6LGfqsDivJwRwEmhMJrCWsx4453JbUyVUnD",
//             initialSupply: 1e25,
//             interval: 30,
//             erc6551Registry: 0x000000006551c19487814612e58FE06813775758, 
//             erc6551Implementation: payable(s_erc6551Implementation),
//             callbackGasLimit: 50000
//         });

//         console.logAddress(address(s_erc6551Implementation));

//         return sepoliaConfig;
//     }

//     function getOPSepoliaEthConfig() public returns (NetworkConfig memory) {

//         vm.startBroadcast();
//         s_erc6551Implementation = new LoyaltyCard6551Account();
//         vm.stopBroadcast();

//         NetworkConfig memory opSepoliaConfig = NetworkConfig({
//             chainid: 11155420,
//             uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/Qmac3tnopwY6LGfqsDivJwRwEmhMJrCWsx4453JbUyVUnD",
//             initialSupply: 1e25,
//             interval: 30,
//             erc6551Registry: 0x000000006551c19487814612e58FE06813775758,
//             erc6551Implementation: payable(s_erc6551Implementation),
//             callbackGasLimit: 50000
//         });

//         console.logAddress(address(s_erc6551Implementation));
//         return opSepoliaConfig;
//     }

//     function getBaseSepoliaConfig() public returns (NetworkConfig memory) {

//         vm.startBroadcast();
//         s_erc6551Implementation = new LoyaltyCard6551Account();
//         vm.stopBroadcast();

//         NetworkConfig memory baseSepoliaConfig = NetworkConfig({
//             chainid: 11155420,
//             uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/Qmac3tnopwY6LGfqsDivJwRwEmhMJrCWsx4453JbUyVUnD",
//             initialSupply: 1e25,
//             interval: 30,
//             erc6551Registry: 0x000000006551c19487814612e58FE06813775758,
//             erc6551Implementation: payable(s_erc6551Implementation),
//             callbackGasLimit: 50000
//         });

//         console.logAddress(address(s_erc6551Implementation));
//         return baseSepoliaConfig;
//     }

//     function getArbitrumSepoliaEthConfig() public returns (NetworkConfig memory) {
//         // £todo this should be included in the actual deploy script.  
//         vm.startBroadcast();
//         s_erc6551Implementation = new LoyaltyCard6551Account();
//         vm.stopBroadcast();

//         NetworkConfig memory arbitrumSepoliaConfig = NetworkConfig({
//             chainid: 421614,
//             uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/Qmac3tnopwY6LGfqsDivJwRwEmhMJrCWsx4453JbUyVUnD",
//             initialSupply: 1e25,
//             interval: 30,
//             erc6551Registry: 0x000000006551c19487814612e58FE06813775758, // = v0.3.1 
//             erc6551Implementation: payable(s_erc6551Implementation),
//             callbackGasLimit: 50000
//         });

//         console.logAddress(address(s_erc6551Implementation)); 
//         return arbitrumSepoliaConfig;
//     }

//     function getMumbaiMaticConfig() public returns (NetworkConfig memory) {
//         vm.startBroadcast();
//         s_erc6551Implementation = new LoyaltyCard6551Account();
//         vm.stopBroadcast();

//         NetworkConfig memory mumbaiPolygonConfig = NetworkConfig({
//             chainid: 80001,
//             uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/Qmac3tnopwY6LGfqsDivJwRwEmhMJrCWsx4453JbUyVUnD",
//             initialSupply: 1e25,
//             interval: 30,
//             erc6551Registry: 0x000000006551c19487814612e58FE06813775758, // = v0.3.1 
//             erc6551Implementation: payable(s_erc6551Implementation),
//             callbackGasLimit: 50000
//         });

//         console.logAddress(address(s_erc6551Implementation)); 
//         return mumbaiPolygonConfig;
//     }

//     function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
//         address ercImplementation = address(0xCE2d5249Ad4042641956c3E016c3D97F7cCfB908);
        
//         try vm.envString("ERC6551_ACCOUNT_IMPLEMENTED") {console.log("ERC6551_ACCOUNT_IMPLEMENTED");  } 
//         catch {
//             console.log("SETTING UP NEW ERC6551 IMPLEMENTATION"); 
//             vm.startBroadcast();
//             s_erc6551Implementation = new LoyaltyCard6551Account{salt: SALT}();
//             vm.stopBroadcast();
            
//             vm.setEnv("ERC6551_ACCOUNT_IMPLEMENTED", "TRUE");
//         }

//         NetworkConfig memory anvilConfig = NetworkConfig({
//             chainid: 31337,
//             erc6551Registry: 0x000000006551c19487814612e58FE06813775758,
//             erc6551Implementation: payable(0xCE2d5249Ad4042641956c3E016c3D97F7cCfB908)
//         });

//         console.log("ERC-6551 Account implementation (should be 0xD240...F7210):", address(s_erc6551Implementation));

//         return anvilConfig;
//     }
// }
