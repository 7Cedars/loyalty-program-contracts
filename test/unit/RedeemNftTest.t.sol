// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol"; 
import {RedeemNft} from "../../src/RedeemNft.sol";
import {DeployRedeemNft} from "../../script/DeployRedeemNft.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RedeemNftTest is Test {
  DeployRedeemNft public deployer; 
  RedeemNft public redeemNft; 
  address public LOYALTY_PROGRAM_CONTRACT = makeAddr("LoyaltyProgramContract"); 
  address public USER_1 = makeAddr("user1"); 
  address public USER_2 = makeAddr("user2"); 
  string public constant SHIBA = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json"; 


  function setUp() public {
    deployer = new DeployRedeemNft(); 
    redeemNft = deployer.run();
  }

  function testNameIsCorrect() public view {
    string memory expectedName = "FreeCoffee"; 
    string memory actualName = redeemNft.name(); 
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
    tokenId = redeemNft.claimNft(USER_1, SHIBA);

    // console.log("SHIBA: ", SHIBA); 
    // console.log("redeemNft.tokenURI(0): ", redeemNft.tokenURI(tokenId)); 

    assert(redeemNft.balanceOf(USER_1) == 1); 
    assert(
      keccak256(abi.encodePacked(SHIBA)) 
      ==
      keccak256(abi.encodePacked(redeemNft.tokenURI(tokenId)))
    );
  }
}
