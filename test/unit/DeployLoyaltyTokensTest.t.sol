// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {DeployOneCoffeeFor2500} from "../../script/DeployLoyaltyTokens.s.sol";
import {OneCoffeeFor2500} from "../../src/PointsForLoyaltyTokens.sol";

contract DeployLoyaltyTokensTest is Test {
    DeployOneCoffeeFor2500 public deployer;
    address public vendorOne = makeAddr("vendor1");

    function setUp() public {
        deployer = new DeployOneCoffeeFor2500();
    }

    function testNameOneCoffeeFor2500IsCorrect() public {
        OneCoffeeFor2500 oneCoffeeFor2500 = deployer.run();

        string memory expectedUri = "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7";
        vm.prank(vendorOne);
        oneCoffeeFor2500.mintLoyaltyTokens(10);
        string memory actualUri = oneCoffeeFor2500.uri(1);
        assert(keccak256(abi.encodePacked(expectedUri)) == keccak256(abi.encodePacked(actualUri)));
    }
}
