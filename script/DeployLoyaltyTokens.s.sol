// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";
import {
    OneCoffeeFor2500, 
    OneCupCakeFor4500, 
    AccessPartyFor50000
    } from "../src/PointsForLoyaltyTokens.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLoyaltyToken is Script {
    function run() external returns (LoyaltyToken) {
        vm.startBroadcast();
        LoyaltyToken loyaltyToken = new LoyaltyToken("ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7");
        vm.stopBroadcast();
        return loyaltyToken;
    }
}

contract DeployMultipleLoyaltyTokens is Script {
    function run() external returns (OneCoffeeFor2500, OneCupCakeFor4500, AccessPartyFor50000) {
        vm.startBroadcast();
        OneCoffeeFor2500 oneCoffeeFor2500 = new OneCoffeeFor2500();
        OneCupCakeFor4500 oneCupCakeFor4500 = new OneCupCakeFor4500();
        AccessPartyFor50000 accessPartyFor50000 = new AccessPartyFor50000();
        vm.stopBroadcast();
        return (oneCoffeeFor2500, oneCupCakeFor4500, accessPartyFor50000);
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

contract DeployOneCupCakeFor4500 is Script {
    function run() external returns (OneCupCakeFor4500) {
        vm.startBroadcast();
        OneCupCakeFor4500 oneCupCakeFor4500 = new OneCupCakeFor4500();
        vm.stopBroadcast();
        return oneCupCakeFor4500;
    }
}

contract DeployAccessPartyFor50000 is Script {
    function run() external returns (AccessPartyFor50000) {
        vm.startBroadcast();
        AccessPartyFor50000 accessPartyFor50000 = new AccessPartyFor50000();
        vm.stopBroadcast();
        return accessPartyFor50000;
    }
}
