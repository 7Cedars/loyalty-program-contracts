// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol"; 
import {LoyaltyNft} from "../../src/LoyaltyNft.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Transaction} from "../../src/LoyaltyProgram.sol" ;
import {DeployLoyaltyNft}from "../../script/DeployLoyaltyNfts.s.sol";

contract LoyaltyNftTest is Test {
  DeployLoyaltyNft public deployer; 
  LoyaltyNft public loyaltyNft;
  address public LOYALTY_PROGRAM_CONTRACT = makeAddr("LoyaltyProgramContract"); 
  address public USER_1 = makeAddr("user1"); 
  address public USER_2 = makeAddr("user2"); 
  Transaction[] public transactions;  
  string public constant FREE_COFFEE_URI = "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7"; 

  modifier usersHaveNfts(
    uint256 numberNfts1,
    uint256 numberNfts2
    ) { 
      vm.prank(LOYALTY_PROGRAM_CONTRACT);
      loyaltyNft.mintNft(75); 

      numberNfts1 = bound(numberNfts1, 3, 8); 
      numberNfts2 = bound(numberNfts2, 18, 21);
      
      // for loop in solidity: initialisation, condition, updating. See https://dev.to/shlok2740/loops-in-solidity-2pmp.
      for (uint256 i = 0; i < numberNfts1; i++) { 
        vm.prank(LOYALTY_PROGRAM_CONTRACT);
        loyaltyNft.claimNft(USER_1); 
      }  
      for (uint256 i = 0; i < numberNfts2; i++) { 
        vm.prank(LOYALTY_PROGRAM_CONTRACT);
        loyaltyNft.claimNft(USER_2); 
      }
      _; 
  }

  function setUp() public {
    deployer = new DeployLoyaltyNft(); 
    loyaltyNft = deployer.run();
  }

  function testNameIsCorrect() public view {
    string memory expectedName = "LoyaltyNft"; 
    string memory actualName = loyaltyNft.name(); 
    // NB you cannot just compare strings! 
    assert(
      keccak256(abi.encodePacked(expectedName))
      ==
      keccak256(abi.encodePacked(actualName))
      ); 
  }

  function testUserCanClaimAndHaveBalance() public { 
    uint256 tokenId; 
    
    vm.prank(LOYALTY_PROGRAM_CONTRACT);
    loyaltyNft.mintNft(20); 
    vm.prank(LOYALTY_PROGRAM_CONTRACT);
    loyaltyNft.claimNft(USER_1);

    assert(loyaltyNft.balanceOf(USER_1) == 1); 
    assert(
      keccak256(abi.encodePacked(FREE_COFFEE_URI)) 
      ==
      keccak256(abi.encodePacked(loyaltyNft.tokenURI(tokenId)))
    );
  }

  function testNftsCanBeTransferredFreely(
    uint256 numberNfts1, 
    uint256 numberNfts2
    ) public usersHaveNfts (
      numberNfts1, numberNfts2
      ) {
        uint256 user1AmountNfts = loyaltyNft.balanceOf(USER_1); 
        uint256 user2AmountNfts = loyaltyNft.balanceOf(USER_2); 

        console.log("user1AmountNfts: ", user1AmountNfts);
        console.log("user2AmountNfts: ", user2AmountNfts);
    
    // vm.prank(USER_1); 
    // loyaltyNft.safeTransferFrom(USER_1, USER_2);
  }

  // function testNftsCanBeRedeemedByOriginalLoyaltyProgram() public usersHaveNfts {

  // }

  // function testNftsCannotBeRedeemedByUser() public usersHaveNfts {

  // }

}
