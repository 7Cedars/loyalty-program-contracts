// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";

contract DeployLoyaltyProgramTest is Test {
    DeployLoyaltyProgram deployer;
    LoyaltyProgram loyaltyProgram;
    uint256 LOYALTYCARDS_TO_MINT = 5;

    function setUp() public {
        string memory rpc_url = vm.envString("SELECTED_RPC_URL"); 
        uint256 forkId = vm.createFork(rpc_url);
        vm.selectFork(forkId);

        deployer = new DeployLoyaltyProgram();
    }

    function testNameDeployedLoyaltyProgramIsCorrect() public {
        string memory uri = "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/Qmac3tnopwY6LGfqsDivJwRwEmhMJrCWsx4453JbUyVUnD"; 

        loyaltyProgram = deployer.run();

        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.mintLoyaltyCards(LOYALTYCARDS_TO_MINT);
        string memory actualUri = loyaltyProgram.uri(1);
        assert(keccak256(abi.encodePacked(uri)) == keccak256(abi.encodePacked(actualUri)));
    }
}
