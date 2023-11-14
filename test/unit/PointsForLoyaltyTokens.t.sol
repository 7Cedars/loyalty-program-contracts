// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {OneCoffeeFor2500} from "../../src/PointsForLoyaltyTokens.sol";
import {DeployOneCoffeeFor2500} from "../../script/DeployLoyaltyTokens.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract ExampleLoyaltyTokensTest is Test {
    DeployOneCoffeeFor2500 public deployer;
}
