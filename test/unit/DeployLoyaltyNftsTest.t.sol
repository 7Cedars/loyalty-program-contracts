// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {
  DeployOneCoffeeFor2500,
  DeployOneCoffeeFor10BuysInWeek, 
  DeployOneCoffeeFor2500And10BuysInWeek
} from "../../script/DeployLoyaltyNfts.s.sol";
import {
  OneCoffeeFor2500, 
  OneCoffeeFor10BuysInWeek, 
  OneCoffeeFor2500And10BuysInWeek
} from "../../src/ExampleLoyaltyNfts.sol";


contract DeployLoyaltyNftsTest is Test {
  DeployOneCoffeeFor2500 public deployerOneCoffeeFor2500; 
  DeployOneCoffeeFor10BuysInWeek public deployerOneCoffeeFor10BuysInWeek; 
  DeployOneCoffeeFor2500And10BuysInWeek public deployerOneCoffeeFor2500And10BuysInWeek; 

  function setUp() public { 
    deployerOneCoffeeFor2500 = new DeployOneCoffeeFor2500();
    deployerOneCoffeeFor10BuysInWeek = new DeployOneCoffeeFor10BuysInWeek();
    deployerOneCoffeeFor2500And10BuysInWeek = new DeployOneCoffeeFor2500And10BuysInWeek();
  }

  function testNameOneCoffeeFor2500IsCorrect() public {
    OneCoffeeFor2500 oneCoffeeFor2500 = deployerOneCoffeeFor2500.run();

    string memory expectedName = "LoyaltyNft"; 
    string memory actualName = oneCoffeeFor2500.name(); 
    // NB you cannot just compare strings! 
    assert(
      keccak256(abi.encodePacked(expectedName))
      ==
      keccak256(abi.encodePacked(actualName))
      ); 
  }

  function testNameOneCoffeeFor10BuysInWeekIsCorrect() public {
    OneCoffeeFor10BuysInWeek oneCoffeeFor10BuysInWeek = deployerOneCoffeeFor10BuysInWeek.run();

    string memory expectedName = "LoyaltyNft"; 
    string memory actualName = oneCoffeeFor10BuysInWeek.name(); 
    // NB you cannot just compare strings! 
    assert(
      keccak256(abi.encodePacked(expectedName))
      ==
      keccak256(abi.encodePacked(actualName))
      ); 
  }
  
  function testNameOneCoffeeFor2500And10BuysInWeekIsCorrect() public {
    OneCoffeeFor2500And10BuysInWeek oneCoffeeFor2500And10BuysInWeek = deployerOneCoffeeFor2500And10BuysInWeek.run();

    string memory expectedName = "LoyaltyNft"; 
    string memory actualName = oneCoffeeFor2500And10BuysInWeek.name(); 
    // NB you cannot just compare strings! 
    assert(
      keccak256(abi.encodePacked(expectedName))
      ==
      keccak256(abi.encodePacked(actualName))
      ); 
  }
}