// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol"; 
import {LoyaltyToken} from "../../src/LoyaltyToken.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployLoyaltyToken}from "../../script/DeployLoyaltyTokens.s.sol";

contract LoyaltyNftTest is Test {
  DeployLoyaltyToken public deployer; 
  LoyaltyToken public loyaltyToken;
  address public loyaltyProgramAddress = makeAddr("LoyaltyProgramContract"); 
  address public userOne = makeAddr("user1"); 
  address public userTwo = makeAddr("user2"); 
  string public constant FREE_COFFEE_URI = "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7"; 

  modifier usersHaveLoyaltyTokens(
    uint256 numberLoyaltyTokens1,
    uint256 numberLoyaltyTokens2
    ) { 
      vm.prank(loyaltyProgramAddress);
      loyaltyToken.mintLoyaltyTokens(75); 

      numberLoyaltyTokens1 = bound(numberLoyaltyTokens1, 11, 35); 
      numberLoyaltyTokens2 = bound(numberLoyaltyTokens2, 18, 21);
      
      // for loop in solidity: initialisation, condition, updating. See https://dev.to/shlok2740/loops-in-solidity-2pmp.
      for (uint256 i = 0; i < numberLoyaltyTokens1; i++) { 
        vm.prank(loyaltyProgramAddress);
        loyaltyToken.claimNft(userOne); 
      }  
      for (uint256 i = 0; i < numberLoyaltyTokens2; i++) { 
        vm.prank(loyaltyProgramAddress);
        loyaltyToken.claimNft(userTwo); 
      }
      _; 
  }

  function setUp() public {
    deployer = new DeployLoyaltyToken(); 
    loyaltyToken = deployer.run();
  }

  function testAnyoneCanMintLoyaltyTokens(uint256 numberOfTokens) public {
    numberOfTokens = bound(numberOfTokens, 10, 99); 
    uint256 numberTokensBefore1; 
    uint256 numberTokensAfter1; 
    uint256 numberTokensBefore2; 
    uint256 numberTokensAfter2; 

    for (uint i = 1; i < numberOfTokens; i++) {
      numberTokensBefore1 = numberTokensBefore1 + loyaltyToken.balanceOf(loyaltyProgramAddress, i); 
    }

    for (uint i = 1; i < numberOfTokens; i++) {
      numberTokensBefore2 = numberTokensBefore2 + loyaltyToken.balanceOf(loyaltyProgramAddress, i); 
    }

    vm.prank(loyaltyProgramAddress);
    loyaltyToken.mintLoyaltyTokens(numberOfTokens); 
    vm.prank(userOne);
    loyaltyToken.mintLoyaltyTokens(numberOfTokens); 

    for (uint i = 1; i < numberOfTokens; i++) {
      numberTokensAfter1 = numberTokensAfter1 + loyaltyToken.balanceOf(loyaltyProgramAddress, i); 
    }

    for (uint i = 1; i < numberOfTokens; i++) {
      numberTokensAfter2 = numberTokensAfter2 + loyaltyToken.balanceOf(loyaltyProgramAddress, i); 
    }

    assertEq(numberTokensBefore1 + numberOfTokens, numberTokensAfter1);
    assertEq(numberTokensBefore2 + numberOfTokens, numberTokensAfter2);
  }

  function testUserCanClaimAndHaveBalance() public { 
    uint256 tokenId; 
    
    vm.prank(loyaltyProgramAddress);
    loyaltyToken.mintLoyaltyTokens(20); 
    vm.prank(loyaltyProgramAddress);
    tokenId = loyaltyToken.claimNft(userOne);

    assert(loyaltyToken.balanceOf(userOne, tokenId) == 1); 
    assert(
      keccak256(abi.encodePacked(FREE_COFFEE_URI)) 
      ==
      keccak256(abi.encodePacked(loyaltyToken.uri(tokenId)))
    );
  }

  function testLoyaltyTokensBoundToLoyaltyProgram() public {
    vm.prank(loyaltyProgramAddress); 
    loyaltyToken.mintLoyaltyTokens(1); 
    console.log("Balance Program before transfer: ", loyaltyToken.balanceOf(loyaltyProgramAddress, 1)); 

    vm.prank(loyaltyProgramAddress); 
    loyaltyToken.claimNft(userOne); 
    console.log("Balance UserOne After transfer: ", loyaltyToken.balanceOf(userOne, 1));

    vm.expectRevert(
      abi.encodeWithSelector(LoyaltyToken.LoyaltyToken__LoyaltyProgramNotRecognised.selector, address(loyaltyToken))
      );  
    vm.prank(userOne); 
    loyaltyToken.redeemNft(userOne, 0); 
  }

  function testUserCannotRedeemNftItDoesNotOwn(uint256 numberOfTokens) public {
    numberOfTokens = bound(numberOfTokens, 11, 25);
    vm.prank(loyaltyProgramAddress); 
    loyaltyToken.mintLoyaltyTokens(numberOfTokens); 
    vm.prank(loyaltyProgramAddress); 
    loyaltyToken.claimNft(userOne); 
    
    vm.expectRevert(
      abi.encodeWithSelector(LoyaltyToken.LoyaltyToken__NftNotOwnedByloyaltyCard.selector, address(loyaltyToken))
      );  
    vm.prank(userOne); 
    loyaltyToken.redeemNft(userOne, 10); 
  }

  // function testLoyaltyTokensCanBeTransferredFreely(
  //   uint256 numberLoyaltyTokens1, 
  //   uint256 numberLoyaltyTokens2
  //   ) public usersHaveLoyaltyTokens (
  //     numberLoyaltyTokens1, numberLoyaltyTokens2
  //     ) {
  //       uint256 user1AmountLoyaltyTokens = loyaltyToken.balanceOf(userOne); 
  //       uint256 user2AmountLoyaltyTokens = loyaltyToken.balanceOf(userTwo);

  //       assert(user1AmountLoyaltyTokens > 0);
  //       assert(user2AmountLoyaltyTokens > 0);
    
  //   // vm.prank(userOne); 
  //   // loyaltyToken.safeTransferFrom(userOne, userTwo);
  // }

  /**
   * @dev Because the base LoyaltyNFT contract does NOT have any requirements
   * set, it should always return true. 
   */
  function testRequirementsNftMetAlwaysReturnsTrue(
    address, 
    uint256, 
    uint input1, 
    uint input2, 
    uint loyaltyPoints, 
    uint256 numberLoyaltyTokens1, 
    uint256 numberLoyaltyTokens2
  ) public usersHaveLoyaltyTokens (
      numberLoyaltyTokens1, numberLoyaltyTokens2
      ) {
    input1 = bound(input1, 0, 2); 
    input2 = bound(input2, 0, 2); 
    address[3] memory addressList = [userOne, userTwo, loyaltyProgramAddress]; 
    address consumer = addressList[input1]; 
    address vendor = addressList[input2]; 
    loyaltyPoints = bound(loyaltyPoints, 1, 10000);
    
    vm.prank(vendor); 
    bool success = loyaltyToken.requirementsLoyaltyTokenMet(consumer, loyaltyPoints); 

    assertEq(success, true); 
  }

}
