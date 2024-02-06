// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {ERC6551Registry} from "../test/mocks/ERC6551Registry.sol";

contract DeployRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEFAULT_ANVIL_KEY_0"); // MAINNET_PRIVATE_KEY
        vm.startBroadcast(deployerPrivateKey);

        new ERC6551Registry{
            salt: 0x6551655165516551655165516551655165516551655165516551655165516551
        }();

        vm.stopBroadcast();
    }
}
