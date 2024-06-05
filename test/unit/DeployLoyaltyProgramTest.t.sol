// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {LoyaltyCard6551Account} from "../../src/LoyaltyCard6551Account.sol";

contract DeployLoyaltyProgramTest is Test {
    DeployLoyaltyProgram deployer;
    LoyaltyProgram loyaltyProgram;
    LoyaltyCard6551Account loyaltyCardAccount; 
    uint256 LOYALTYCARDS_TO_MINT = 5;

    function setUp() public {
        string memory rpc_url = vm.envString("SELECTED_RPC_URL"); 
        uint256 forkId = vm.createFork(rpc_url);
        vm.selectFork(forkId);

        deployer = new DeployLoyaltyProgram();
    }

    function testNameDeployedLoyaltyProgramIsCorrect() public {
        string memory uri = "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmfA8Sf8YxigXGapwqMXCAB6fPQUPWugav5xKzJPVG6uo6"; 

        (loyaltyProgram, loyaltyCardAccount) = deployer.run();

        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.mintLoyaltyCards(LOYALTYCARDS_TO_MINT);
        string memory actualUri = loyaltyProgram.uri(1);
        assert(keccak256(abi.encodePacked(uri)) == keccak256(abi.encodePacked(actualUri)));
    }
}
