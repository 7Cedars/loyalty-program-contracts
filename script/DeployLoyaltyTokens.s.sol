// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";
import {OneCoffeeFor2500} from "../src/PointsForLoyaltyTokens.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLoyaltyToken is Script {
    function run() external returns (LoyaltyToken) {
        vm.startBroadcast();
        LoyaltyToken loyaltyToken = new LoyaltyToken("ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7");
        vm.stopBroadcast();
        return loyaltyToken;
    }
}

contract DeployOneCoffeeFor2500 is Script {
    function run() external returns (OneCoffeeFor2500) {
        vm.startBroadcast();
        OneCoffeeFor2500 oneCoffeeFor2500 = new OneCoffeeFor2500();
        vm.stopBroadcast();
        return oneCoffeeFor2500;
    }
}
