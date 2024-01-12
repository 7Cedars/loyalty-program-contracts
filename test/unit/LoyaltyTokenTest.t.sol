// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {LoyaltyToken} from "../../src/LoyaltyToken.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployLoyaltyToken} from "../../script/DeployLoyaltyTokens.s.sol";

///////////////////////////////////////////////
///                   Setup                 ///
///////////////////////////////////////////////

contract LoyaltyTokenTest is Test {
    DeployLoyaltyToken public deployer;
    LoyaltyToken public loyaltyToken;
    address public loyaltyProgramAddress = makeAddr("LoyaltyProgramContract");
    address public userOne = makeAddr("user1");
    address public userTwo = makeAddr("user2");
    string public constant FREE_COFFEE_URI = "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7";

    modifier usersHaveLoyaltyTokens(uint256 numberLoyaltyTokens1, uint256 numberLoyaltyTokens2) {
        vm.prank(loyaltyProgramAddress);
        loyaltyToken.mintLoyaltyTokens(75);

        numberLoyaltyTokens1 = bound(numberLoyaltyTokens1, 11, 35);
        numberLoyaltyTokens2 = bound(numberLoyaltyTokens2, 18, 21);

        // for loop in solidity: initialisation, condition, updating. See https://dev.to/shlok2740/loops-in-solidity-2pmp.
        for (uint256 i = 0; i < numberLoyaltyTokens1; i++) {
            vm.prank(loyaltyProgramAddress);
            loyaltyToken.claimLoyaltyToken(userOne);
        }
        for (uint256 i = 0; i < numberLoyaltyTokens2; i++) {
            vm.prank(loyaltyProgramAddress);
            loyaltyToken.claimLoyaltyToken(userTwo);
        }
        _;
    }

    function setUp() public {
        deployer = new DeployLoyaltyToken();
        loyaltyToken = deployer.run();
    }

    ///////////////////////////////////////////////
    ///         Test Minting LoyaltyPoints      ///
    ///////////////////////////////////////////////

    function testAnyoneCanMintLoyaltyTokens(uint256 numberOfTokens) public {
        numberOfTokens = bound(numberOfTokens, 10, 99);
        uint256 numberTokensBefore1;
        uint256 numberTokensAfter1;
        uint256 numberTokensBefore2;
        uint256 numberTokensAfter2;

        for (uint256 i = 1; i < numberOfTokens; i++) {
            numberTokensBefore1 = numberTokensBefore1 + loyaltyToken.balanceOf(loyaltyProgramAddress, i);
        }

        for (uint256 i = 1; i < numberOfTokens; i++) {
            numberTokensBefore2 = numberTokensBefore2 + loyaltyToken.balanceOf(loyaltyProgramAddress, i);
        }

        vm.prank(loyaltyProgramAddress);
        loyaltyToken.mintLoyaltyTokens(numberOfTokens);
        vm.prank(userOne);
        loyaltyToken.mintLoyaltyTokens(numberOfTokens);

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            numberTokensAfter1 = numberTokensAfter1 + loyaltyToken.balanceOf(loyaltyProgramAddress, i);
        }

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            numberTokensAfter2 = numberTokensAfter2 + loyaltyToken.balanceOf(loyaltyProgramAddress, i);
        }

        assertEq(numberTokensBefore1 + numberOfTokens, numberTokensAfter1);
        assertEq(numberTokensBefore2 + numberOfTokens, numberTokensAfter2);
    }

    /////////////////////////////////////////////////////////
    ///      Test Requirements Check Loyalty Tokens       ///
    /////////////////////////////////////////////////////////

    function testUserCanClaimAndHaveBalance() public {
        uint256 tokenId;

        vm.prank(loyaltyProgramAddress);
        loyaltyToken.mintLoyaltyTokens(20);
        vm.prank(loyaltyProgramAddress);
        loyaltyToken.claimLoyaltyToken(userOne);

        assert(loyaltyToken.balanceOf(userOne, 19) == 1);
        assert(keccak256(abi.encodePacked(FREE_COFFEE_URI)) == keccak256(abi.encodePacked(loyaltyToken.uri(tokenId))));
    }

    function testUserCanCheckAvailableTokens() public {
        uint256[] memory numberOfTokens;

        vm.prank(loyaltyProgramAddress);
        loyaltyToken.mintLoyaltyTokens(20);
        vm.prank(loyaltyProgramAddress);
        loyaltyToken.claimLoyaltyToken(userOne);

        numberOfTokens = loyaltyToken.getAvailableTokens(userOne);

        for (uint256 i = 1; i < numberOfTokens.length; i++) {
            console.logUint(numberOfTokens[i]); 
        }
        
        
    }

    /////////////////////////////////////////////////////////
    ///     Test Claiming and Redeeming Loyalty Tokens    ///
    /////////////////////////////////////////////////////////

    /// See integration tests /// 

    
}
