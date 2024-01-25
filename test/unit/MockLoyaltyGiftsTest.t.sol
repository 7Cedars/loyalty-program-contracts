// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {LoyaltyGift} from "../../src/mocks/LoyaltyGift.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployMockLoyaltyGifts} from "../../script/DeployLoyaltyGifts.s.sol";

// ///////////////////////////////////////////////
// ///                   Setup                 ///
// ///////////////////////////////////////////////

// contract LoyaltyGiftTest is Test {
//     DeployLoyaltyGift public deployer;
//     LoyaltyGift public loyaltyToken;
//     address public loyaltyProgramAddress = makeAddr("LoyaltyProgramContract");
//     address public userOne = makeAddr("user1");
//     address public userTwo = makeAddr("user2");

//     modifier usersHaveLoyaltyGifts(uint256 numberLoyaltyGifts1, uint256 numberLoyaltyGifts2) {
//         vm.prank(loyaltyProgramAddress);
//         loyaltyToken.mintLoyaltyGifts(75);

//         numberLoyaltyGifts1 = bound(numberLoyaltyGifts1, 11, 35);
//         numberLoyaltyGifts2 = bound(numberLoyaltyGifts2, 18, 21);

//         // for loop in solidity: initialisation, condition, updating. See https://dev.to/shlok2740/loops-in-solidity-2pmp.
//         for (uint256 i = 0; i < numberLoyaltyGifts1; i++) {
//             vm.prank(loyaltyProgramAddress);
//             loyaltyToken.claimLoyaltyGift(userOne);
//         }
//         for (uint256 i = 0; i < numberLoyaltyGifts2; i++) {
//             vm.prank(loyaltyProgramAddress);
//             loyaltyToken.claimLoyaltyGift(userTwo);
//         }
//         _;
//     }

//     function setUp() public {
//         deployer = new DeployLoyaltyGift();
//         loyaltyToken = deployer.run();
//     }

//     ///////////////////////////////////////////////
//     ///         Test Minting LoyaltyPoints      ///
//     ///////////////////////////////////////////////

//     function testAnyoneCanMintLoyaltyGifts(uint256 numberOfTokens) public {
//         numberOfTokens = bound(numberOfTokens, 10, 99);
//         uint256 numberTokensBefore1;
//         uint256 numberTokensAfter1;
//         uint256 numberTokensBefore2;
//         uint256 numberTokensAfter2;

//         for (uint256 i = 1; i < numberOfTokens; i++) {
//             numberTokensBefore1 = numberTokensBefore1 + loyaltyToken.balanceOf(loyaltyProgramAddress, i);
//         }

//         for (uint256 i = 1; i < numberOfTokens; i++) {
//             numberTokensBefore2 = numberTokensBefore2 + loyaltyToken.balanceOf(loyaltyProgramAddress, i);
//         }

//         vm.prank(loyaltyProgramAddress);
//         loyaltyToken.mintLoyaltyGifts(numberOfTokens);
//         vm.prank(userOne);
//         loyaltyToken.mintLoyaltyGifts(numberOfTokens);

//         for (uint256 i = 1; i <= numberOfTokens; i++) {
//             numberTokensAfter1 = numberTokensAfter1 + loyaltyToken.balanceOf(loyaltyProgramAddress, i);
//         }

//         for (uint256 i = 1; i <= numberOfTokens; i++) {
//             numberTokensAfter2 = numberTokensAfter2 + loyaltyToken.balanceOf(loyaltyProgramAddress, i);
//         }

//         assertEq(numberTokensBefore1 + numberOfTokens, numberTokensAfter1);
//         assertEq(numberTokensBefore2 + numberOfTokens, numberTokensAfter2);
//     }

//     /////////////////////////////////////////////////////////
//     ///      Test Requirements Check Loyalty Tokens       ///
//     /////////////////////////////////////////////////////////

//     function testUserCanClaimAndHaveBalance() public {
//         uint256 tokenId;

//         vm.prank(loyaltyProgramAddress);
//         loyaltyToken.mintLoyaltyGifts(20);
//         vm.prank(loyaltyProgramAddress);
//         loyaltyToken.claimLoyaltyGift(userOne);

//         assert(loyaltyToken.balanceOf(userOne, 19) == 1);
//         assert(keccak256(abi.encodePacked(FREE_COFFEE_URI)) == keccak256(abi.encodePacked(loyaltyToken.uri(tokenId))));
//     }

//     function testUserCanCheckAvailableTokens() public {
//         uint256[] memory numberOfTokens;

//         vm.prank(loyaltyProgramAddress);
//         loyaltyToken.mintLoyaltyGifts(20);
//         vm.prank(loyaltyProgramAddress);
//         loyaltyToken.claimLoyaltyGift(userOne);

//         numberOfTokens = loyaltyToken.getAvailableTokens(userOne);

//         for (uint256 i = 1; i < numberOfTokens.length; i++) {
//             console.logUint(numberOfTokens[i]); 
//         }
        
        
//     }

//     /////////////////////////////////////////////////////////
//     ///     Test Claiming and Redeeming Loyalty Tokens    ///
//     /////////////////////////////////////////////////////////

//     /// See integration tests /// 

    
// }
