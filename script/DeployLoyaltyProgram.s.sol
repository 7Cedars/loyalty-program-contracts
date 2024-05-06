// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {LoyaltyProgram} from "../src/LoyaltyProgram.sol";
import {MockLoyaltyGifts} from "../test/mocks/MockLoyaltyGifts.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract DeployLoyaltyProgram is Script {
    LoyaltyProgram loyaltyProgram;

    // NB: If I need a helper config, see helperConfig.s.sol + learning/foundry-fund-me-f23
    function run() external returns (LoyaltyProgram) {
        string memory uri = "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmU3uuSj2wiL5e19pvymT4WejPF67q4qaQWtAC7YiSxCoE"; 
        string memory name = "Loyalty Program"; 
        string memory version = "alpha.2";

        vm.startBroadcast();
            loyaltyProgram = new LoyaltyProgram(
            uri, 
            name,
            version
        );
        vm.stopBroadcast();

        return (loyaltyProgram); 
    }
}
