// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import { MockLoyaltyGifts } from "../src/mocks/MockLoyaltyGifts.sol";
import { LoyaltyGift } from "../src/mocks/LoyaltyGift.sol";

contract DeployMockLoyaltyGifts is Script {

    function run() external returns (MockLoyaltyGifts) {
        vm.startBroadcast();
        MockLoyaltyGifts mockGifts = new MockLoyaltyGifts();
        vm.stopBroadcast();
        return mockGifts;
    }
}

contract DeployLoyaltyGift is Script {

    // create a config file for this? -- decide later. 
    uint256[] public tokenised = [0, 1]; // 0 == false, 1 == true.  

    function run() external returns (LoyaltyGift) {
        vm.startBroadcast();
        LoyaltyGift loyaltyGift = new LoyaltyGift(
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmSshfobzx5jtA14xd7zJ1PtmG8xFaPkAq2DZQagiAkSET/{id}", 
            tokenised
        );
        vm.stopBroadcast();
        return loyaltyGift;
    }
}

