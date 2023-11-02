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
  address public loyaltyProgramAddress = makeAddr("LoyaltyProgramContract"); 
  address public userOne = makeAddr("user1"); 
  address public userTwo = makeAddr("user2"); 
  Transaction[] public transactions;  
  string public constant FREE_COFFEE_URI = "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7"; 

  modifier usersHaveNfts(
    uint256 numberNfts1,
    uint256 numberNfts2
    ) { 
      vm.prank(loyaltyProgramAddress);
      loyaltyNft.mintNft(75); 

      numberNfts1 = bound(numberNfts1, 11, 35); 
      numberNfts2 = bound(numberNfts2, 18, 21);
      
      // for loop in solidity: initialisation, condition, updating. See https://dev.to/shlok2740/loops-in-solidity-2pmp.
      for (uint256 i = 0; i < numberNfts1; i++) { 
        vm.prank(loyaltyProgramAddress);
        loyaltyNft.claimNft(userOne); 
      }  
      for (uint256 i = 0; i < numberNfts2; i++) { 
        vm.prank(loyaltyProgramAddress);
        loyaltyNft.claimNft(userTwo); 
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

  // this test is I thnk not 100% ok.. anyhow. 
  function testAnyoneCanMintNfts(uint256 numberOfNfts) public {
    numberOfNfts = bound(numberOfNfts, 10, 99); 

    vm.prank(loyaltyProgramAddress);
    loyaltyNft.mintNft(numberOfNfts); 
    vm.prank(userOne);
    loyaltyNft.mintNft(numberOfNfts); 
    vm.prank(userTwo);
    loyaltyNft.mintNft(numberOfNfts); 

    assertEq(numberOfNfts, loyaltyNft.balanceOf(loyaltyProgramAddress));
    assertEq(numberOfNfts, loyaltyNft.balanceOf(userOne));
    assertEq(numberOfNfts, loyaltyNft.balanceOf(userTwo)); 
  }

  function testUserCanClaimAndHaveBalance() public { 
    uint256 tokenId; 
    
    vm.prank(loyaltyProgramAddress);
    loyaltyNft.mintNft(20); 
    vm.prank(loyaltyProgramAddress);
    loyaltyNft.claimNft(userOne);

    assert(loyaltyNft.balanceOf(userOne) == 1); 
    assert(
      keccak256(abi.encodePacked(FREE_COFFEE_URI)) 
      ==
      keccak256(abi.encodePacked(loyaltyNft.tokenURI(tokenId)))
    );
  }

  function testCannotRedeemNftMintedBySomeoneElse(uint256 numberOfNfts) public {
    numberOfNfts = bound(numberOfNfts, 3, 99);
    vm.prank(loyaltyProgramAddress); 
    loyaltyNft.mintNft(numberOfNfts); 
    console.log("Balance Program before transfer: ", loyaltyNft.balanceOf(loyaltyProgramAddress)); 

    vm.prank(loyaltyProgramAddress); 
    loyaltyNft.claimNft(userOne); 
    console.log("Balance UserOne After transfer: ", loyaltyNft.balanceOf(userOne));

    vm.expectRevert(
      abi.encodeWithSelector(LoyaltyNft.LoyaltyNft__IncorrectNftContract.selector, address(loyaltyNft))
      );  
    vm.prank(userOne); 
    loyaltyNft.redeemNft(userOne, 0); 
  }

  function testUserCannotRedeemNftItDoesNotOwn(uint256 numberOfNfts) public {
    numberOfNfts = bound(numberOfNfts, 11, 25);
    vm.prank(loyaltyProgramAddress); 
    loyaltyNft.mintNft(numberOfNfts); 
    vm.prank(loyaltyProgramAddress); 
    loyaltyNft.claimNft(userOne); 
    
    vm.expectRevert(
      abi.encodeWithSelector(LoyaltyNft.LoyaltyNft__NftNotOwnedByConsumer.selector, address(loyaltyNft))
      );  
    vm.prank(userOne); 
    loyaltyNft.redeemNft(userOne, 10); 
  }

  function testNftsCanBeTransferredFreely(
    uint256 numberNfts1, 
    uint256 numberNfts2
    ) public usersHaveNfts (
      numberNfts1, numberNfts2
      ) {
        uint256 user1AmountNfts = loyaltyNft.balanceOf(userOne); 
        uint256 user2AmountNfts = loyaltyNft.balanceOf(userTwo);

        assert(user1AmountNfts > 0);
        assert(user2AmountNfts > 0);
    
    // vm.prank(userOne); 
    // loyaltyNft.safeTransferFrom(userOne, userTwo);
  }

  /**
   * @dev Because the base LoyaltyNFT contract does NOT have any requirements
   * set, it should always return true. 
   */
  function testRequirementsNftMetAlwaysReturnsTrue(
    address, 
    uint256, 
    Transaction[] memory,
    uint input1, 
    uint input2, 
    uint loyaltyPoints, 
    uint256 numberNfts1, 
    uint256 numberNfts2
  ) public usersHaveNfts (
      numberNfts1, numberNfts2
      ) {
    input1 = bound(input1, 0, 2); 
    input2 = bound(input2, 0, 2); 
    address[3] memory addressList = [userOne, userTwo, loyaltyProgramAddress]; 
    address consumer = addressList[input1]; 
    address vendor = addressList[input2]; 
    loyaltyPoints = bound(loyaltyPoints, 1, 10000);
    
    vm.prank(vendor); 
    bool success = loyaltyNft.requirementsNftMet(consumer, loyaltyPoints, transactions); 

    assertEq(success, true); 
  }

  function testRequirementsNftMetFailsIfNftUnavailable(
    address, 
    uint256, 
    Transaction[] memory
  ) public {
    
    vm.prank(loyaltyProgramAddress); 
    bool success = loyaltyNft.requirementsNftMet(userOne, 3000, transactions); 

    assertEq(success, false); 
  }

}
