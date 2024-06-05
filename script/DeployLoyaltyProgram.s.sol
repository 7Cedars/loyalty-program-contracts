// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {LoyaltyProgram} from "../src/LoyaltyProgram.sol";
import {MockLoyaltyGifts} from "../test/mocks/MockLoyaltyGifts.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {LoyaltyCard6551Account} from "../src/LoyaltyCard6551Account.sol";

contract DeployLoyaltyProgram is Script {
    LoyaltyProgram loyaltyProgram;
    LoyaltyCard6551Account loyaltyCard6551Account; 

    LoyaltyCard6551Account demoAccount = new LoyaltyCard6551Account{salt: 0x0000000000000000000000000000000000000000000000000000000007ceda52}();

    // £note: If I need a helper config, see helperConfig.s.sol + learning/foundry-fund-me-f23
    function run() external returns (LoyaltyProgram, LoyaltyCard6551Account) {
        string memory uri = "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmfA8Sf8YxigXGapwqMXCAB6fPQUPWugav5xKzJPVG6uo6"; 
        string memory name = "Loyalty Program"; 
        string memory version = "alpha.3";

        vm.startBroadcast();
            // address accountAddress = vm.computeCreateAddress(address(this), 1); 
            // console2.log("calculated accountAddress: ", accountAddress); 
            uint256 codeLength = address(demoAccount).code.length; 
            console2.log("demoAccount codeLength: ", codeLength); 
            if (codeLength == 0) { 
                loyaltyCard6551Account = new LoyaltyCard6551Account{salt: 0x0000000000000000000000000000000000000000000000000000000007ceda52}(); 
                console2.log("loyaltyCard6551Account address: ", address(loyaltyCard6551Account));
            } 
            
            loyaltyProgram = new LoyaltyProgram(
            uri, 
            name,
            version,
            address(demoAccount)
        );
        vm.stopBroadcast();

        return (loyaltyProgram, demoAccount); 
    }
}
