// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol"; 
import {LoyaltyNft} from "../../src/LoyaltyNft.sol";
import {DeployLoyaltyNft} from "../../script/DeployLoyaltyNft.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LoyaltyNftTest is Test {
  DeployLoyaltyNft public deployer; 
  LoyaltyNft public loyaltyNft; 
  address public LOYALTY_PROGRAM_CONTRACT = makeAddr("LoyaltyProgramContract"); 
  address public USER_1 = makeAddr("user1"); 
  address public USER_2 = makeAddr("user2"); 
  string public constant FREE_COFFEE_URI = "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7"; 


  function setUp() public {
    deployer = new DeployLoyaltyNft(); 
    loyaltyNft = deployer.run();
  }

  function testNameIsCorrect() public view {
    string memory expectedName = "FreeCoffee"; 
    string memory actualName = loyaltyNft.name(); 
    // NB you cannot just compare strings! 
    assert(
      keccak256(abi.encodePacked(expectedName))
      ==
      keccak256(abi.encodePacked(actualName))
      ); 
  }

  function testCanMintAndHaveBalance() public { 
    uint256 tokenId; 
    
    vm.prank(LOYALTY_PROGRAM_CONTRACT); 
    tokenId = loyaltyNft.claimNft(USER_1);

    // console.log("SHIBA: ", SHIBA); 
    // console.log("LoyaltyNft.tokenURI(0): ", LoyaltyNft.tokenURI(tokenId)); 

    assert(loyaltyNft.balanceOf(USER_1) == 1); 
    assert(
      keccak256(abi.encodePacked(FREE_COFFEE_URI)) 
      ==
      keccak256(abi.encodePacked(loyaltyNft.tokenURI(tokenId)))
    );
  }
}
