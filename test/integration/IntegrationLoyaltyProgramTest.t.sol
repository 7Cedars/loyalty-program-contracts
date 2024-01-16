// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.21;

// import {Test} from "forge-std/Test.sol";
// import {console} from "forge-std/console.sol";
// import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
// import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
// import {ERC6551Account} from "../../src/ERC6551Account.sol";
// import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
// import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// // NB: invariant (stateful fuzz) testing in foundry see PC course at 3:23 - Implement! 
// // at 3.45: handlers. 


// contract IntegrationLoyaltyProgramTest is Test {
//     /* events */
//     event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
//     event AddedLoyaltyGiftContract(address indexed loyaltyToken);
//     event RemovedLoyaltyGiftContract(address indexed loyaltyToken);

//     ///////////////////////////////////////////////
//     ///                   Setup                 ///
//     ///////////////////////////////////////////////

//     LoyaltyProgram loyaltyProgramA;
//     LoyaltyProgram loyaltyProgramB;
//     HelperConfig helperConfig;
//     uint256 minCustomerInteractions;
//     uint256 maxCustomerInteractions;
//     uint256 minPointsPerInteraction;
//     uint256 maxPointsPerInteraction;
//     address public vendorA;
//     address public vendorB;
//     uint256 internal customerOnePrivateKey; 
//     uint256 internal customerTwoPrivateKey; 
//     uint256 internal customerThreePrivateKey; 
//     address internal customerOne;
//     address internal customerTwo; 
//     address internal customerThree;
//     address public loyaltyTokenContractA = makeAddr("loyaltyTokenA");
//     address public loyaltyTokenContractB = makeAddr("loyaltyTokenB");
//     address payable tokenOneProgramA;
//     address payable tokenTwoProgramA;
//     address payable tokenOneProgramB;
//     address payable tokenTwoProgramB;
//     uint256 public constant LOYALTY_POINTS = 0;
//     uint256 constant STARTING_BALANCE = 10 ether;
//     uint256 constant GAS_PRICE = 1;
//     bytes resultTransfer;

//     using MessageHashUtils for bytes32;
//     using ECDSA for bytes32;

//     /**
//      * @dev this modifier sets up a fuzzy context consisting of
//      * - 2 customers,
//      */
//     modifier setUpContext() 
//     {
//         // transfer single loyalty card to customers
//         vm.prank(vendorA);
//         loyaltyProgramA.safeTransferFrom(vendorA, customerOne, 1, 1, "");
//         vm.prank(vendorA);
//         loyaltyProgramA.safeTransferFrom(vendorA, customerTwo, 2, 1, "");
//         vm.prank(vendorB);
//         loyaltyProgramB.safeTransferFrom(vendorB, customerTwo, 1, 1, "");
//         vm.prank(vendorB);
//         loyaltyProgramB.safeTransferFrom(vendorB, customerThree, 2, 1, "");

//         _;
//     }

//     function setUp() external {
//         DeployLoyaltyProgram deployerProgram = new DeployLoyaltyProgram();
//         DeployOneCoffeeFor2500 deployerToken = new DeployOneCoffeeFor2500();
//         loyaltyProgramA = deployerProgram.run();
//         loyaltyProgramB = deployerProgram.run();
//         loyaltyToken2500 = deployerToken.run();

//         vendorA = loyaltyProgramA.getOwner();
//         vendorB = loyaltyProgramB.getOwner();

//         customerOnePrivateKey = 0xA11CE; 
//         customerTwoPrivateKey = 0xF155E; 
//         customerThreePrivateKey = 0xB210E; 

//         customerOne = vm.addr(customerOnePrivateKey);
//         customerTwo = vm.addr(customerTwoPrivateKey);
//         customerThree = vm.addr(customerThreePrivateKey);

//         // minting loyalty cards and points by vendors
//         vm.prank(vendorA);
//         loyaltyProgramA.mintLoyaltyCards(3);
//         vm.prank(vendorA);
//         loyaltyProgramA.mintLoyaltyPoints(500000);
//         vm.prank(vendorB);
//         loyaltyProgramB.mintLoyaltyCards(7);
//         vm.prank(vendorB);
//         loyaltyProgramB.mintLoyaltyPoints(1500000);

//         // getting addresses of tokenBoundAccounts
//         tokenOneProgramA = payable(loyaltyProgramA.getTokenBoundAddress(1));
//         tokenTwoProgramA = payable(loyaltyProgramA.getTokenBoundAddress(2));
//         tokenOneProgramB = payable(loyaltyProgramB.getTokenBoundAddress(1));
//         tokenTwoProgramB = payable(loyaltyProgramB.getTokenBoundAddress(2));

//         // Transfer points to loyalty cards
//         // This will later be fuzzed.
//         vm.startPrank(vendorA);
//         loyaltyProgramA.safeTransferFrom(vendorA, tokenOneProgramA, 0, 50000, "");
//         loyaltyProgramA.safeTransferFrom(vendorA, tokenTwoProgramA, 0, 65000, "");
//         vm.stopPrank();
        
//         vm.prank(vendorB);
//         loyaltyProgramB.safeTransferFrom(vendorB, tokenOneProgramB, 0, 2500, "");
//         vm.prank(vendorB);
//         loyaltyProgramB.safeTransferFrom(vendorB, tokenTwoProgramB, 0, 5550, "");
//     }

//     ////////////////////////////////////////////////////////////////
//     /// Test Transfer LoyaltyPoints between Loyalty Card Holders ///
//     ////////////////////////////////////////////////////////////////

//     function testLoyaltyPointsAreTransferableBetweenLoyaltyCards()
//         // uint256 numberOfLoyaltyPoints -- for fuzzy testing
//         public
//         setUpContext
//     {
//         uint256 balanceBeforeSender;
//         uint256 balanceBeforeReceiver;
//         uint256 balanceAfterReceiver;
//         uint256 numberOfLoyaltyPoints = 10;

//         balanceBeforeSender = loyaltyProgramA.getBalanceLoyaltyCard(1);
//         balanceBeforeReceiver = loyaltyProgramA.getBalanceLoyaltyCard(2);

//         vm.prank(customerOne);
//         ERC6551Account(tokenOneProgramA).executeCall(
//             payable(loyaltyProgramA),
//             0,
//             abi.encodeCall(
//                 IERC1155.safeTransferFrom,
//                 (tokenOneProgramA, tokenTwoProgramA, LOYALTY_POINTS, numberOfLoyaltyPoints, "")
//             )
//         );

//         balanceAfterReceiver = loyaltyProgramA.getBalanceLoyaltyCard(2);
//         assertEq(balanceBeforeReceiver + numberOfLoyaltyPoints, balanceAfterReceiver);
//     }

//     // console.log("resultTransfer: ", resultTransfer);

//     // function testLoyaltyGiftsAreTransferableBetweenLoyaltyCards(
//     //   uint256 numberOfLoyaltyPoints
//     //   ) public setUpContext {
//     //     uint256 balanceBeforeSender;
//     //     uint256 balanceBeforeReceiver;
//     //     uint256 balanceAfterReceiver;

//     //     balanceBeforeSender = loyaltyProgramA.getBalanceLoyaltyCard(2);
//     //     numberOfLoyaltyPoints = bound(numberOfLoyaltyPoints, 1, balanceBeforeSender);
//     //     balanceBeforeReceiver = loyaltyProgramA.getBalanceLoyaltyCard(3);

//     //     vm.prank(customerOne);
//     //     loyaltyProgramA.safeTransferFrom(
//     //       tokenOneProgramA, // owned by customerOne
//     //       tokenTwoProgramA, // owned by customerTwo
//     //       0, numberOfLoyaltyPoints, "");
//     //     balanceAfterReceiver = loyaltyProgramA.getBalanceLoyaltyCard(3);
//     //     assertEq(balanceBeforeReceiver + numberOfLoyaltyPoints, balanceAfterReceiver);
//     // }

//     /////////////////////////////////////////////////////////////
//     ///   Test Minting and Redeeming Loyalty Points          ////
//     /////////////////////////////////////////////////////////////

//     function testCustomerCanRedeemLoyaltyPoints() public setUpContext {
//         uint256 numberOfLoyaltyPoints = 2502;

//         // whitelist loyalty token contract..
//         vm.prank(vendorA);
//         loyaltyProgramA.addLoyaltyGiftContract(payable(address(loyaltyToken2500)));

//         // mint loyalty tokens..
//         vm.prank(vendorA);
//         loyaltyProgramA.mintLoyaltyGifts(payable(address(loyaltyToken2500)), 10);

//         // customer calls loyalty token contract from loyaltycard to
//         // redeem points for loyalty token.
//         vm.prank(customerOne);
//         ERC6551Account(tokenOneProgramA).executeCall(
//             payable(loyaltyProgramA),
//             0,
//             abi.encodeCall(LoyaltyProgram.redeemLoyaltyPoints, (payable(address(loyaltyToken2500)), numberOfLoyaltyPoints, 1))
//         );
//     }

//     /////////////////////////////////////////////////////////
//     ///           Test Redeeming Loyalty Tokens          ////
//     /////////////////////////////////////////////////////////
//     // this still needs to be expanded with negative tests: checinking if all reverts work.
//     // while setting up these tests this seemed to be the case.

//     function testOwnerCanMintLoyaltyGifts() public setUpContext {
//         uint256 numberOfLoyaltyGiftsRequested = 10;
//         uint256 numberOfLoyaltyGiftsReceived = 0;

//         // whitelist loyalty token contract..
//         vm.prank(vendorA);
//         loyaltyProgramA.addLoyaltyGiftContract(payable(address(loyaltyToken2500)));

//         // mint loyalty tokens..
//         vm.prank(vendorA);
//         loyaltyProgramA.mintLoyaltyGifts(payable(address(loyaltyToken2500)), numberOfLoyaltyGiftsRequested);

//         for (uint256 i = 1; i <= numberOfLoyaltyGiftsRequested; i++) {
//             numberOfLoyaltyGiftsReceived =
//                 numberOfLoyaltyGiftsReceived + loyaltyToken2500.balanceOf(address(loyaltyProgramA), i);
//         }

//         assertEq(numberOfLoyaltyGiftsRequested, numberOfLoyaltyGiftsReceived);
//     }

//     function testCustomerCanRedeemLoyaltyGifts() public setUpContext {
//         // Setup:
//         // First mint tokens and redeem loyalty points
//         uint256 numberOfLoyaltyPoints = 2502;

//         // whitelist loyalty token contract..
//         vm.prank(vendorA);
//         loyaltyProgramA.addLoyaltyGiftContract(payable(address(loyaltyToken2500)));

//         // mint loyalty tokens..
//         vm.prank(vendorA);
//         loyaltyProgramA.mintLoyaltyGifts(payable(address(loyaltyToken2500)), 10);

//         // customer calls loyalty token contract from loyaltycard to
//         // redeem points for loyalty token.

//         vm.prank(customerOne);
//         uint256 ownsLoyaltyCard = loyaltyProgramA.balanceOf(customerOne, 1);
//         console.log("ownsLoyaltyCard", ownsLoyaltyCard);

//         vm.prank(customerOne);
//         ERC6551Account(tokenOneProgramA).executeCall(
//             payable(loyaltyProgramA),
//             0,
//             abi.encodeCall(
//                 LoyaltyProgram.redeemLoyaltyPoints, 
//                 (payable(address(loyaltyToken2500)), 
//                 numberOfLoyaltyPoints, 
//                 1)
//                 )
//         );

//         uint256 balanceToken10 = loyaltyToken2500.balanceOf(tokenOneProgramA, 10);
//         console.log("balanceToken10", balanceToken10);

//         // // now try and redeem this token...
//         // vm.prank(customerOne);
//         // ERC6551Account(tokenOneProgramA).executeCall(
//         //     payable(loyaltyProgramA),
//         //     0,
//         //     abi.encodeCall(
//         //         LoyaltyProgram.redeemLoyaltyGift, 
//         //         (payable(address(loyaltyToken2500)), 
//         //         10,
//         //         LoyaltyProgram.getTokenBoundAddress(1)
//         //      )
//         //     )
//         // );
//     }

//     // See explanation here: https://book.getfoundry.sh/tutorials/testing-eip712
//     function testCustomerCanClaimLoyaltyPointsThroughSignedMessage() public setUpContext {
//         // Setup:
//         uint256 numberOfLoyaltyPoints = 5000;
//         uint256 nonce = 1; 
        
//         // whitelist loyalty token contract & mint tokens ..
//         vm.startPrank(vendorA);
//         loyaltyProgramA.addLoyaltyGiftContract(payable(address(loyaltyToken2500)));
//         loyaltyProgramA.mintLoyaltyGifts(payable(address(loyaltyToken2500)), 10);
//         vm.stopPrank();  
//         // customer calls loyalty token contract from loyaltycard to
//         // redeem points for loyalty token.

//         vm.startPrank(customerOne);
//         bytes32 messageHash = keccak256(
//             abi
//             .encodePacked(
//                 payable(address(loyaltyToken2500)), // address loyaltyToken,
//                 customerOne, // address customerAddress, 
//                 numberOfLoyaltyPoints, // uint256 loyaltyPoints, 
//                 nonce
//             )).toEthSignedMessageHash();

//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOnePrivateKey, messageHash); 
//         bytes memory signature = abi.encodePacked(r, s, v); 
//         vm.stopPrank(); 

//         console.logAddress(customerOne);
//         console.logAddress(address(vendorA));
//         console.logAddress(address(loyaltyProgramA.getTokenBoundAddress(1)));
//         console.logAddress(address(loyaltyProgramA));
//         console.logAddress(address(loyaltyToken2500));
        
//         /////////////////
//         vm.startPrank(vendorA); 
//         loyaltyProgramA.redeemLoyaltyPointsUsingSignedMessage(
//             address(loyaltyToken2500), // address payable loyaltyToken,
//             loyaltyProgramA.getTokenBoundAddress(1), // address loyaltyCardAddress,
//             customerOne, 
//             5000, // uint256 loyaltyPoints, 
//             1, // uint nonce, // can, I think, be blocknumber. --just meant so same type of request do not end up being reverted. 
//             signature // signature bytes32
//         ); 
//         vm.stopPrank();

//         uint256 balanceToken10 = loyaltyToken2500.balanceOf(tokenOneProgramA, 10);
//         console.log("balanceToken10", balanceToken10);
//     }

//        // See explanation here: https://book.getfoundry.sh/tutorials/testing-eip712
//     function testCustomerCanRedeemLoyaltyGiftThroughSignedMessage() public setUpContext {
//         // Setup:
//         uint256 nonce = 1; 
//         uint256 loyaltyTokenId = 9; 
//         uint256 numberOfLoyaltyPoints = 5000;
        
//         // whitelist loyalty token contract & mint tokens ..
//         vm.startPrank(vendorA);
//         loyaltyProgramA.addLoyaltyGiftContract(payable(address(loyaltyToken2500)));
//         loyaltyProgramA.mintLoyaltyGifts(payable(address(loyaltyToken2500)), 10);
//         vm.stopPrank(); 

//         // customer One claims token
//         vm.prank(customerOne);
//         ERC6551Account(tokenOneProgramA).executeCall(
//             payable(loyaltyProgramA),
//             0,
//             abi.encodeCall(
//                 LoyaltyProgram.redeemLoyaltyPoints, 
//                 (payable(address(loyaltyToken2500)), 
//                 numberOfLoyaltyPoints, 
//                 1)
//                 )
//         );

//         // Now redeeming this token through signed message: Create signature by customer  
//         vm.startPrank(customerOne);
//         bytes32 messageHash = keccak256(
//             abi
//             .encodePacked(
//                 payable(loyaltyToken2500), // address loyaltyToken,
//                 loyaltyTokenId,
//                 customerOne, 
//                 loyaltyProgramA.getTokenBoundAddress(1), // uint256 loyaltyPoints, 
//                 nonce
//             )).toEthSignedMessageHash();

//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOnePrivateKey, messageHash); 
//         bytes memory signature = abi.encodePacked(r, s, v); 
//         vm.stopPrank(); 
        
//         // Use signature as approval to redeem token by vendor. 
//         vm.startPrank(vendorA); 
//         loyaltyProgramA.redeemLoyaltyGiftUsingSignedMessage(
//             payable(loyaltyToken2500), // address payable loyaltyToken,
//             customerOne, // address customerAddress, 
//             loyaltyTokenId, // loyaltyTokenId
//             loyaltyProgramA.getTokenBoundAddress(1) // address loyaltyCardAddress,
//             // nonce, // uint nonce, // can, I think, be blocknumber. --just meant so same type of request do not end up being reverted. 
//             // signature // signature bytes32
//         ); 
//         vm.stopPrank();

//         uint256 balanceToken10 = loyaltyToken2500.balanceOf(tokenOneProgramA, 9);
//         console.log("balanceToken10", balanceToken10);
//     }


//     // function testOwnerCanTransferTokenstouserOne(uint256 amount) public {
//     //   // Arrange
//     //   uint256 balanceOwnerBefore = loyaltyProgramA.balanceOf(loyaltyProgramA.getOwner());
//     //   uint256 balanceUser1Before = loyaltyProgramA.balanceOf(customerOne);
//     //   amount = bound(amount, 10, loyaltyProgramA.totalSupply());

//     //   // Act
//     //   vm.prank(loyaltyProgramA.getOwner());
//     //   loyaltyProgramA.transfer(customerOne, amount);

//     //   // Assert
//     //   uint256 balanceOwnerAfter = loyaltyProgramA.balanceOf(loyaltyProgramA.getOwner());
//     //   uint256 balanceUser1After = loyaltyProgramA.balanceOf(customerOne);
//     //   assertEq(loyaltyProgramA.balanceOf(customerOne), balanceUser1Before + amount);
//     //   assertEq(balanceUser1Before + amount, balanceUser1After);
//     //   assertEq(balanceOwnerBefore - amount, balanceOwnerAfter);
//     // }

//     // function testEmitsEventOnTransferTokens(uint256 amount) public {
//     //   // Arrange
//     //   // use vm.recordLogs(); ?
//     //   // after action
//     //   // vm.Log[] memory entries = vm.getRecordLogs();

//     //   amount = bound(amount, 15, 2500);
//     //   vm.expectEmit(true, false, false, false, address(loyaltyProgramA));
//     //   emit Transfer(loyaltyProgramA.getOwner(), customerOne, amount);

//     //   // Act / Assert
//     //   vm.prank(loyaltyProgramA.getOwner());
//     //   loyaltyProgramA.transfer(customerOne, amount);
//     // }

//     // function testUserCannotTransferTokenstoOtherUser(uint256 amount) public usersHaveTransactionHistory() {
//     //   // Arrange
//     //   amount = bound(amount, 0, loyaltyProgramA.balanceOf(customerOne));
//     //   // Act / Assert
//     //   vm.expectRevert(LoyaltyProgramA.LoyaltyProgramA__NoAccess.selector);
//     //   vm.prank(customerOne);
//     //   // vm.prank(loyaltyProgramA.getOwner());
//     //   loyaltyProgramA.transfer(customerTwo, 10);
//     // }

//     //////////////////////////////////////////////////////////////////
//     /// Test Transfer Loyalty Tokens Between Loyalty Card Holders ////
//     //////////////////////////////////////////////////////////////////
// }
