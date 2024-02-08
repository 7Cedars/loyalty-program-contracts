// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC6551Registry} from "../mocks/ERC6551Registry.sol";

contract LoyaltyProgramTest is Test {
    /* events */
    event DeployedLoyaltyProgram(address indexed owner, string name, string version);
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values
    );
    event AddedLoyaltyGift(address indexed loyaltyGift, uint256 loyaltyGiftId);
    event RemovedLoyaltyGiftClaimable(address indexed loyaltyGift, uint256 loyaltyGiftId);
    event RemovedLoyaltyGiftRedeemable(address indexed loyaltyGift, uint256 loyaltyGiftId);

    ///////////////////////////////////////////////
    ///                   Setup                 ///
    ///////////////////////////////////////////////

    LoyaltyProgram loyaltyProgram;
    HelperConfig helperConfig;

    uint256 CARDS_TO_MINT = 5;
    uint256[] CARDS_MINTED = [1, 2, 3, 4, 5];
    uint256[] CARDS_AMOUNT = [1, 1, 1, 1, 1];
    uint256 POINTS_TO_MINT = 500000000;
    uint256[] GIFTS_TO_SELECT = [0, 3, 5];
    uint256[] TOKENS_TO_MINT = [3, 5];
    uint256[] AMOUNT_TOKENS_TO_MINT = [24, 34];
    uint256[] GIFTS_TO_DESELECT = [2];
    address MOCK_LOYALTY_GIFT_ADDRESS = 0xbdEd0D2bf404bdcBa897a74E6657f1f12e5C6fb6;
    uint256 SALT = 3947539732098357;

    uint256 vendorKey = vm.envUint("DEFAULT_ANVIL_KEY_0");
    address vendorAddress = vm.addr(vendorKey);

    function setUp() external {
        DeployLoyaltyProgram deployer = new DeployLoyaltyProgram();
        (loyaltyProgram, helperConfig) = deployer.run();
    }

    function testLoyaltyProgramHasOwner() public {
        assertNotEq(address(0), loyaltyProgram.getOwner());
    }

    function testDeployEmitsevent() public {
        string memory name = "Loyalty Program"; 
        string memory version = "1"; 
        (, string memory uri,,, address erc65511Registry, address payable erc65511Implementation,) =
            helperConfig.activeNetworkConfig();

        vm.expectEmit(true, false, false, false);
        emit DeployedLoyaltyProgram(vendorAddress, name, version);

        vm.prank(vendorAddress);
        loyaltyProgram = new LoyaltyProgram(
        uri, 
        name, 
        version,
        erc65511Registry,
        erc65511Implementation
        );
    }

    ///////////////////////////////////////////////
    ///      Test Mint Points and Cards         ///
    ///////////////////////////////////////////////

    function testLoyaltyProgramMintsPoints() public {
        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.mintLoyaltyPoints(POINTS_TO_MINT);

        assertEq(loyaltyProgram.balanceOf(loyaltyProgram.getOwner(), 0), POINTS_TO_MINT);
    }

    function testMintingPointsEmitsEvent() public {
        vm.expectEmit(true, false, false, false, address(loyaltyProgram));

        emit TransferSingle(
            loyaltyProgram.getOwner(), // address indexed operator,
            loyaltyProgram.getOwner(), // address indexed from,
            loyaltyProgram.getOwner(), // address indexed to,
            0, // uint256 id,
            POINTS_TO_MINT // uint256 value
        );

        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.mintLoyaltyPoints(POINTS_TO_MINT);
    }

    function testLoyaltyProgramMintsCards() public {
        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.mintLoyaltyCards(CARDS_TO_MINT);

        for (uint256 i = 1; i < CARDS_TO_MINT + 1; i++) {
            assertEq(loyaltyProgram.balanceOf(loyaltyProgram.getOwner(), i), 1);
        }
    }

    function testMintingCardsEmitsEvent() public {
        vm.expectEmit(true, false, false, false, address(loyaltyProgram));
        emit TransferBatch(
            loyaltyProgram.getOwner(), // address indexed operator,
            loyaltyProgram.getOwner(), // address indexed from,
            loyaltyProgram.getOwner(), // address indexed to,
            CARDS_MINTED,
            CARDS_AMOUNT
        );

        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.mintLoyaltyCards(CARDS_TO_MINT);
    }

    function testMintingCardsCreatesValidTokenBasedAccounts() public {
        (uint256 chainid,,,, address erc65511Registry, address payable erc65511Implementation,) =
            helperConfig.activeNetworkConfig();

        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.mintLoyaltyCards(CARDS_TO_MINT);

        for (uint256 i = 0; i < CARDS_MINTED.length; i++) {
            address deployedTBAAccount;
            deployedTBAAccount = loyaltyProgram.getTokenBoundAddress(CARDS_MINTED[i]);

            address registryComputedAddress = ERC6551Registry(erc65511Registry).account(
                address(erc65511Implementation), chainid, address(loyaltyProgram), CARDS_MINTED[i], SALT
            );

            assertEq(deployedTBAAccount, registryComputedAddress);
        }
    }

    ///////////////////////////////////////////////
    ///    Adding and Removing LoyaltyGifts      //
    ///////////////////////////////////////////////

    function testLoyaltyGiftContractCanBeAdded() public {
        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.addLoyaltyGift(MOCK_LOYALTY_GIFT_ADDRESS, 0);
        // Act / Assert
        assertEq(loyaltyProgram.getLoyaltyGiftsIsClaimable(MOCK_LOYALTY_GIFT_ADDRESS, 0), 1);
        assertEq(loyaltyProgram.getLoyaltyGiftsIsRedeemable(MOCK_LOYALTY_GIFT_ADDRESS, 0), 1);
    }

    function testEmitsEventOnAddingLoyaltyGiftContract() public {
        // Arrange
        vm.expectEmit(true, false, false, false, address(loyaltyProgram));
        emit AddedLoyaltyGift(MOCK_LOYALTY_GIFT_ADDRESS, 0);
        // Act / Assert
        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.addLoyaltyGift(payable(MOCK_LOYALTY_GIFT_ADDRESS), 0);
    }

    function testLoyaltyGiftClaimCanBeRemoved() public {
        vm.startPrank(loyaltyProgram.getOwner());
        loyaltyProgram.addLoyaltyGift(MOCK_LOYALTY_GIFT_ADDRESS, 0);
        loyaltyProgram.removeLoyaltyGiftClaimable(MOCK_LOYALTY_GIFT_ADDRESS, 0);
        vm.stopPrank();

        // Act / Assert
        assertEq(loyaltyProgram.getLoyaltyGiftsIsClaimable(MOCK_LOYALTY_GIFT_ADDRESS, 0), 0);
        assertEq(loyaltyProgram.getLoyaltyGiftsIsRedeemable(MOCK_LOYALTY_GIFT_ADDRESS, 0), 1);
    }

    function testLoyaltyGiftRedeemCanBeRemoved() public {
        vm.startPrank(loyaltyProgram.getOwner());
        loyaltyProgram.addLoyaltyGift(MOCK_LOYALTY_GIFT_ADDRESS, 0);
        loyaltyProgram.removeLoyaltyGiftRedeemable(MOCK_LOYALTY_GIFT_ADDRESS, 0);
        vm.stopPrank();

        // Act / Assert
        assertEq(loyaltyProgram.getLoyaltyGiftsIsClaimable(MOCK_LOYALTY_GIFT_ADDRESS, 0), 0);
        assertEq(loyaltyProgram.getLoyaltyGiftsIsRedeemable(MOCK_LOYALTY_GIFT_ADDRESS, 0), 0);
    }

    function testEmitsEventOnRemovingLoyaltyGiftClaim() public {
        // Arrange
        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.addLoyaltyGift(MOCK_LOYALTY_GIFT_ADDRESS, 0);

        vm.expectEmit(true, false, false, false, address(loyaltyProgram));
        emit RemovedLoyaltyGiftClaimable(MOCK_LOYALTY_GIFT_ADDRESS, 0);

        // Act / Assert
        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.removeLoyaltyGiftClaimable(MOCK_LOYALTY_GIFT_ADDRESS, 0);
    }

    function testEmitsEventOnRemovingLoyaltyGiftRedeem() public {
        // Arrange
        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.addLoyaltyGift(MOCK_LOYALTY_GIFT_ADDRESS, 0);

        vm.expectEmit(true, false, false, false, address(loyaltyProgram));
        emit RemovedLoyaltyGiftRedeemable(MOCK_LOYALTY_GIFT_ADDRESS, 0);

        // Act / Assert
        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.removeLoyaltyGiftRedeemable(MOCK_LOYALTY_GIFT_ADDRESS, 0);
    }
}

///////////////////////////////////////////////
///     Claim Gifts and redeem Vouchers      //
///////////////////////////////////////////////

// For Claim Gifts and redeem Vouchers tests see interaction tests.

//     function testOwnerCanMintLoyaltyCards(uint256 numberToMint) public {
//         uint256 totalSupplyBefore;
//         uint256 totalSupplyAfter;
//         uint256 totalLoyaltyCardsMinted;
//         uint256 i;

//         numberToMint = bound(numberToMint, 1, 5);
//         totalLoyaltyCardsMinted = loyaltyProgramA.getNumberLoyaltyCardsMinted();

//         for (i = 1; i <= totalLoyaltyCardsMinted; i++) {
//             totalSupplyBefore = totalSupplyBefore + loyaltyProgramA.balanceOf(vendorA, i);
//         }

//         // Act
//         vm.prank(vendorA);
//         loyaltyProgramA.mintLoyaltyCards(numberToMint);

//         totalLoyaltyCardsMinted = loyaltyProgramA.getNumberLoyaltyCardsMinted();
//         for (i = 1; i <= totalLoyaltyCardsMinted; i++) {
//             totalSupplyAfter = totalSupplyAfter + loyaltyProgramA.balanceOf(vendorA, i);
//         }

//         // Assert
//         assertEq(totalSupplyBefore + numberToMint, totalSupplyAfter);
//     }

//     function testOwnerCanTransferLoyaltyCards(uint256 idToTransfer) public setUpContext {
//         uint256 i;
//         vm.prank(vendorA);
//         loyaltyProgramA.mintLoyaltyPoints(1e25);
//         vm.prank(vendorA);
//         loyaltyProgramA.mintLoyaltyCards(50);

//         idToTransfer = bound(idToTransfer, 3, 5);

//         for (i = 3; i <= idToTransfer; i++) {
//             vm.prank(vendorA);
//             loyaltyProgramA.safeTransferFrom(vendorA, customerOne, i, 1, "");
//         }

//         for (i = 3; i <= idToTransfer; i++) {
//             assertEq(loyaltyProgramA.balanceOf(customerOne, i), 1);
//         }
//     }

//     function testOwnerCannotTransferLoyaltyCardsItDoesNotOwn(uint256 numberToMint) public {
//         address owner = loyaltyProgramA.getOwner();

//         numberToMint = bound(numberToMint, 10, 50);
//         vm.prank(loyaltyProgramA.getOwner());
//         loyaltyProgramA.mintLoyaltyCards(numberToMint);

//         uint256 numberLoyaltyCards = loyaltyProgramA.getNumberLoyaltyCardsMinted();

//         vm.expectRevert();
//         vm.prank(owner);
//         loyaltyProgramA.safeTransferFrom(owner, customerOne, (numberLoyaltyCards + 5), 1, "");
//     }

//     //////////////////////////////////////////////////////
//     ///     Test Mint, Gift, Transfer LoyaltyPoints    ///
//     //////////////////////////////////////////////////////

//     function testOwnerCanMintLoyaltyPoints(uint256 amount) public {
//         uint256 totalSupplyBefore;
//         uint256 totalSupplyAfter;

//         amount = bound(amount, 10, 1e20);
//         totalSupplyBefore = loyaltyProgramA.balanceOf(vendorA, 0);

//         // Act
//         vm.prank(vendorA);
//         loyaltyProgramA.mintLoyaltyPoints(amount);
//         totalSupplyAfter = loyaltyProgramA.balanceOf(vendorA, 0);

//         // Assert
//         assertEq(totalSupplyBefore + amount, totalSupplyAfter);
//     }

//     function testCustomerCannotMintLoyaltyPoints(uint256 amount) public {
//         amount = bound(amount, 10, 1e20);

//         // Act
//         vm.expectRevert(LoyaltyProgram.LoyaltyProgram__OnlyOwner.selector);
//         vm.prank(customerOne);
//         loyaltyProgramA.mintLoyaltyPoints(amount);
//     }

//     function testOwnerProgramCanTransferLoyaltyPoints(uint256 numberOfLoyaltyPoints) public setUpContext {
//         uint256 balanceVendorA;
//         uint256 balanceBefore;
//         uint256 balanceAfter;

//         balanceVendorA = loyaltyProgramA.balanceOf(vendorA, 0);
//         numberOfLoyaltyPoints = bound(numberOfLoyaltyPoints, 0, balanceVendorA % 40);
//         balanceBefore = loyaltyProgramA.getBalanceLoyaltyCard(1);

//         console.log("vendorA: ", vendorA);
//         address tokenAddress = loyaltyProgramA.getTokenBoundAddress(1);
//         vm.prank(vendorA);
//         loyaltyProgramA.safeTransferFrom(vendorA, tokenAddress, 0, numberOfLoyaltyPoints, "");
//         balanceAfter = loyaltyProgramA.getBalanceLoyaltyCard(1);
//         assertEq(balanceBefore + numberOfLoyaltyPoints, balanceAfter);
//     }

//     function testCannotTransferLoyaltyPointsToCustomer(uint256 numberOfLoyaltyPoints) public setUpContext {
//         uint256 balanceVendorA = loyaltyProgramA.balanceOf(vendorA, 0);
//         bound(numberOfLoyaltyPoints, 1, balanceVendorA / 4);

//         vm.expectRevert(LoyaltyProgram.LoyaltyProgram__TransferDenied.selector);
//         vm.prank(vendorA);
//         loyaltyProgramA.safeTransferFrom(vendorA, customerOne, 0, numberOfLoyaltyPoints, "");
//     }

//     /////////////////////////////////////////////////////
//     /// Test Adding, Removing Loyalty Token Contracts ///
//     /////////////////////////////////////////////////////

//     function testOwnerCanAddLoyaltyTokenContract() public {
//         // Act
//         vm.prank(vendorB);
//         loyaltyProgramB.addLoyaltyTokenContract(payable(loyaltyTokenContractA));

//         // Assert
//         assertEq(loyaltyProgramB.getLoyaltyTokensClaimable(loyaltyTokenContractA), 1);
//         assertEq(loyaltyProgramB.getLoyaltyTokensClaimable(address(0)), 0);
//     }

//     function testEmitsEventOnAddingLoyaltyTokenContract() public {
//         // Arrange
//         vm.expectEmit(true, false, false, false, address(loyaltyProgramA));
//         emit AddedLoyaltyTokenContract(loyaltyTokenContractA);
//         // Act / Assert
//         vm.prank(vendorA);
//         loyaltyProgramA.addLoyaltyTokenContract(payable(loyaltyTokenContractA));
//     }

//     function testOwnerCanRemoveLoyaltyTokenContract() public {
//         // Arrange
//         vm.prank(vendorA);
//         loyaltyProgramA.addLoyaltyTokenContract(payable(loyaltyTokenContractA));
//         assertEq(loyaltyProgramA.getLoyaltyTokensClaimable(loyaltyTokenContractA), 1);

//         // Act
//         vm.prank(vendorA);
//         loyaltyProgramA.removeLoyaltyTokenClaimable(loyaltyTokenContractA);

//         // Assert
//         assertEq(loyaltyProgramA.getLoyaltyTokensClaimable(loyaltyTokenContractA), 0);
//     }

//     function testEmitsEventOnRemovingloyaltyTokenContract() public {
//         // Arrange
//         vm.prank(vendorA);
//         loyaltyProgramA.addLoyaltyTokenContract(payable(loyaltyTokenContractA));
//         assertEq(loyaltyProgramA.getLoyaltyTokensClaimable(loyaltyTokenContractA), 1);

//         vm.expectEmit(true, false, false, false, address(loyaltyProgramA));
//         emit RemovedLoyaltyTokenClaimable(loyaltyTokenContractA);

//         // Act / Assert
//         vm.prank(vendorA);
//         loyaltyProgramA.removeLoyaltyTokenClaimable(loyaltyTokenContractA);
//     }

//     function testCustomerCannotAddLoyaltyTokenContracts() public {
//         vm.expectRevert(LoyaltyProgram.LoyaltyProgram__OnlyOwner.selector);
//         vm.prank(customerThree);
//         loyaltyProgramA.addLoyaltyTokenContract(payable(loyaltyTokenContractA));

//         console.log(address(vendorA));
//         console.log(address(vendorB));
//     }

//     function testCustomerCannotRemoveLoyaltyTokenContracts() public {
//         vm.expectRevert(LoyaltyProgram.LoyaltyProgram__OnlyOwner.selector);
//         vm.prank(customerTwo);
//         loyaltyProgramB.removeLoyaltyTokenClaimable(loyaltyTokenContractB);
//     }

//     /////////////////////////////////////////////////////
//     /////       Test claiming and redeeming Tokens  /////
//     /////////////////////////////////////////////////////

//     // function testLoyaltyCardCanExchangePointsForToken() public {
//     //     // Arrange
//     //     vm.prank(vendorA);
//     //     loyaltyProgramA.addLoyaltyTokenContract(payable(loyaltyTokenContractA));
//     //     vm.prank(vendorA);
//     //     loyaltyProgramA.mintLoyaltyTokens(payable(loyaltyTokenContractA), 50);

//     //     vm.prank(vendorA);
//     //     loyaltyProgramA.safeTransferFrom(vendorA, customerOne, 2, 1, "");

//     //     // Assert
//     //     assertEq(loyaltyProgramA.getLoyaltyToken(loyaltyTokenContractA), 0);
//     // }

// }
