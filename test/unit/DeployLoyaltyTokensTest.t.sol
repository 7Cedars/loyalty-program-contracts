// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {
  DeployOneCoffeeFor2500
} from "../../script/DeployLoyaltyTokens.s.sol";
import {
  OneCoffeeFor2500
} from "../../src/PointsForLoyaltyTokens.sol";


contract DeployLoyaltyNftsTest is Test {
  DeployOneCoffeeFor2500 public deployerOneCoffeeFor2500; 
  address public vendorOne = makeAddr("vendor1"); 

  function setUp() public { 
    deployerOneCoffeeFor2500 = new DeployOneCoffeeFor2500();
  }

  function testNameOneCoffeeFor2500IsCorrect() public {
    OneCoffeeFor2500 oneCoffeeFor2500 = deployerOneCoffeeFor2500.run();


    string memory expectedUri = "https://ipfs.io/ipfs/QmcPwXFUayuEETYJvd3QaLU9Xtjkxte9rgBgfEjD2MBvJ5.json"; 
    oneCoffeeFor2500.mintLoyaltyTokens(10); 
    string memory actualUri = oneCoffeeFor2500.uri(1); 
    // NB you cannot just compare strings! 
    assert(
      keccak256(abi.encodePacked(expectedUri))
      ==
      keccak256(abi.encodePacked(actualUri))
      ); 
  }
}