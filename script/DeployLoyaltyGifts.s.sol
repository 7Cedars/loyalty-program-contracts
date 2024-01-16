// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyGift} from "../src/LoyaltyGift.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLoyaltyGift is Script {
    uint256[] public TOKENISED = [0, 0, 0, 1, 1, 1]; // 0 == false, 1 == true.  
    string public URI = "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmX5em6Dh4XgnZ6pe4igkZqkf6mSRTRbNja2w3qE8qcfGT"; 


    function run() external returns (LoyaltyGift) {
        vm.startBroadcast();
        LoyaltyGift loyaltyToken = new LoyaltyGift(URI, TOKENISED);
        vm.stopBroadcast();
        return loyaltyToken;
    }
}
