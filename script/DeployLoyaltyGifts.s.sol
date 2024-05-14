// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {MockLoyaltyGifts} from "../test/mocks/MockLoyaltyGifts.sol";
 import {MockLoyaltyGift} from "../test/mocks/MockLoyaltyGift.sol";

contract DeployMockLoyaltyGifts is Script {
    function run() external returns (MockLoyaltyGifts) {
        vm.startBroadcast();
        MockLoyaltyGifts mockGifts = new MockLoyaltyGifts();
        vm.stopBroadcast();
        return mockGifts;
    }
}
