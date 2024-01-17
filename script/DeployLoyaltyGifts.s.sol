// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {MockLoyaltyGifts} from "../src/MockLoyaltyGifts.sol";

contract DeployMockLoyaltyGifts is Script {

    function run() external returns (MockLoyaltyGifts) {
        vm.startBroadcast();
        MockLoyaltyGifts loyaltyToken = new MockLoyaltyGifts();
        vm.stopBroadcast();
        return loyaltyToken;
    }
}
