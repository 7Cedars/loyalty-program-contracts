// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MockLoyaltyGifts} from "../test/mocks/MockLoyaltyGifts.sol";
import {MockLoyaltyGift} from "../test/mocks/MockLoyaltyGift.sol";
import {LoyaltyCard6551Account} from "../src/LoyaltyCard6551Account.sol";

contract DeployMockLoyaltyGifts is Script {
    LoyaltyCard6551Account public s_erc6551Implementation;

    function run() external returns (bool success) {
        vm.startBroadcast();
        s_erc6551Implementation = new LoyaltyCard6551Account{salt: 0x0000000000000000000000000000000000000000000000000000000007ceda52}();
        vm.stopBroadcast();
        
        console.log("CHECK: erc6551Implementation deployed at 0xD240...F7210", address(s_erc6551Implementation)); 
        return true;
    }
}
