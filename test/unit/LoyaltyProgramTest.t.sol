// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console, console2} from "forge-std/Test.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {LoyaltyCard6551Account} from "../../src/LoyaltyCard6551Account.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC6551Registry} from "@erc6551/ERC6551Registry.sol"; 
import {ILoyaltyGift} from "../../src/interfaces/ILoyaltyGift.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {DeployMockLoyaltyGifts} from "../../script/DeployLoyaltyGifts.s.sol";
import {DeployMockERC1155} from "../../script/DeployMockERC1155.s.sol";

contract LoyaltyProgramTest is Test {
    /* events */
    event DeployedLoyaltyProgram(address indexed owner, string name, string indexed version);
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event AddedLoyaltyGift(address indexed loyaltyGift, uint256 indexed loyaltyGiftId);
    event RemovedLoyaltyGiftClaimable(address indexed loyaltyGift, uint256 indexed loyaltyGiftId);
    event RemovedLoyaltyGiftRedeemable(address indexed loyaltyGift, uint256 indexed loyaltyGiftId);

    LoyaltyProgram loyaltyProgram;
    LoyaltyCard6551Account loyaltyCard6551Account;
    ILoyaltyGift mockLoyaltyGifts; 
    IERC1155 mockERC1155; 
    address ownerProgram; 

    uint256 CARDS_TO_MINT = 5;
    uint256[] CARDS_MINTED = [1, 2, 3, 4, 5];
    uint256[] CARDS_AMOUNT = [1, 1, 1, 1, 1];
    uint256 POINTS_TO_MINT = 500000000;
    uint256[] GIFTS_TO_SELECT = [0, 2, 4];
    uint256[] TOKENS_TO_MINT = [2, 4];
    uint256[] AMOUNT_TOKENS_TO_MINT = [24, 34];
    uint256[] GIFTS_TO_DESELECT = [2];
    bytes32 SALT = 0x0000000000000000000000000000000000000000000000000000000007ceda52;

    uint256 vendorKey = vm.envUint("DEFAULT_ANVIL_KEY_0");
    address vendorAddress = vm.addr(vendorKey);

    ///////////////////////////////////////////////
    ///                   Setup                 ///
    ///////////////////////////////////////////////

    function setUp() external {
        string memory rpc_url = vm.envString("SELECTED_RPC_URL"); 
        uint256 forkId = vm.createFork(rpc_url);
        vm.selectFork(forkId);

        DeployLoyaltyProgram deployer = new DeployLoyaltyProgram();
        (loyaltyProgram, loyaltyCard6551Account) = deployer.run();
        ownerProgram = loyaltyProgram.getOwner(); 

        console2.log("address loyaltyCard6551Account:" , address(loyaltyCard6551Account)); 

        DeployMockLoyaltyGifts deployerGifts = new DeployMockLoyaltyGifts(); 
        (mockLoyaltyGifts) = deployerGifts.run();

        DeployMockERC1155 deployerERC1155 = new DeployMockERC1155(); 
        (mockERC1155) = deployerERC1155.run();
    }

    function testLoyaltyProgramHasOwner() public view {
        assertNotEq(address(0), ownerProgram);
    }

    function testLoyaltyCardCounter() public view {
        assertEq(0, loyaltyProgram.getNumberLoyaltyCardsMinted());
    }

    function testDeployEmitsevent() public {
        string memory name = "Loyalty Program"; 
        string memory version = "testversion02"; 
        string memory uri = "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/Qmac3tnopwY6LGfqsDivJwRwEmhMJrCWsx4453JbUyVUnD"; 

        vm.expectEmit(true, false, false, false);
        emit DeployedLoyaltyProgram(vendorAddress, name, version);

        vm.prank(vendorAddress);
        loyaltyProgram = new LoyaltyProgram(
        uri, 
        name, 
        version, 
        address(loyaltyCard6551Account) 
        );
    }

    ///////////////////////////////////////////////
    ///      Test Mint Points and Cards         ///
    ///////////////////////////////////////////////
    
    // cards
    function testLoyaltyProgramMintsCards() public {
        vm.prank(ownerProgram);
        loyaltyProgram.mintLoyaltyCards(CARDS_TO_MINT);

        for (uint256 i = 1; i < CARDS_TO_MINT + 1; i++) {
            assertEq(loyaltyProgram.balanceOf(ownerProgram, i), 1);
        }
    }

    function testMintingCardsEmitsEvent() public {
        vm.expectEmit(true, false, false, false, address(loyaltyProgram));
        emit TransferBatch(
            ownerProgram, // address indexed operator,
            address(0), // address indexed from,
            ownerProgram, // address indexed to,
            CARDS_MINTED,
            CARDS_AMOUNT
        );

        vm.prank(ownerProgram);
        loyaltyProgram.mintLoyaltyCards(CARDS_TO_MINT);
    }

    function testMintingCardsCreatesValidTokenBasedAccounts() public {
        address erc65511Registry = 0x000000006551c19487814612e58FE06813775758;

        vm.prank(ownerProgram);
        loyaltyProgram.mintLoyaltyCards(CARDS_TO_MINT);

        for (uint256 i = 0; i < CARDS_MINTED.length; i++) {
            address deployedTBAAccount;
            deployedTBAAccount = loyaltyProgram.getTokenBoundAddress(CARDS_MINTED[i]);

            address registryComputedAddress = ERC6551Registry(erc65511Registry).account(
                address(loyaltyCard6551Account), SALT, block.chainid, address(loyaltyProgram), CARDS_MINTED[i] 
            );

            assertEq(deployedTBAAccount, registryComputedAddress);
        }
    }

    function testMintingCardsIncreasesLoyaltyCardCounter() public {
        uint256 counterBefore = loyaltyProgram.getNumberLoyaltyCardsMinted(); 

        vm.prank(ownerProgram);
        loyaltyProgram.mintLoyaltyCards(CARDS_TO_MINT);

        uint256 counterAfter = loyaltyProgram.getNumberLoyaltyCardsMinted(); 
        assertEq(counterBefore + CARDS_TO_MINT, counterAfter);
    }

    // points
    function testLoyaltyProgramMintsPoints() public {
        uint256 balanceBefore = loyaltyProgram.balanceOf(ownerProgram, 0); 

        vm.prank(ownerProgram);
        loyaltyProgram.mintLoyaltyPoints(POINTS_TO_MINT);

        uint256 balanceAfter = loyaltyProgram.balanceOf(ownerProgram, 0); 
        assertEq(balanceBefore + POINTS_TO_MINT, balanceAfter);
    }

    function testMintingPointsEmitsEvent() public {
        vm.expectEmit(true, false, false, false, address(loyaltyProgram));

        emit TransferSingle(
            ownerProgram, // address indexed operator,
            address(0), // address indexed from,
            ownerProgram, // address indexed to,
            0, // uint256 id, 
            POINTS_TO_MINT // uint256 value
        );

        vm.prank(ownerProgram);
        loyaltyProgram.mintLoyaltyPoints(POINTS_TO_MINT);
    }

    ///////////////////////////////////////////////
    ///    Adding and Removing LoyaltyGifts      //
    ///////////////////////////////////////////////
    function testLoyaltyGiftContractCanBeAdded() public {
        vm.prank(ownerProgram);
        loyaltyProgram.addLoyaltyGift(address(mockLoyaltyGifts), 0);
        // Act / Assert
        assertEq(loyaltyProgram.getLoyaltyGiftIsClaimable(address(mockLoyaltyGifts), 0), true);
        assertEq(loyaltyProgram.getLoyaltyGiftIsRedeemable(address(mockLoyaltyGifts), 0), true);
    }

    function testAddingGiftContractRevertsWithIncorrectInterfaceId() public {
        vm.expectRevert(
            abi.encodeWithSelector(LoyaltyProgram.LoyaltyProgram__IncorrectInterface.selector, address(address(mockERC1155))) 
        );
        
        vm.prank(ownerProgram);
        loyaltyProgram.addLoyaltyGift(address(mockERC1155), 0);
    }

    // £todo this one currently fails with a [FAIL. Reason: log != expected log] error. Except... the log == log. Sort this out later.. 
    function testEmitsEventOnAddingLoyaltyGiftContract() public {
        vm.expectEmit(true, false, false, false, address(loyaltyProgram));
        emit AddedLoyaltyGift(address(mockLoyaltyGifts), 0);
        
        vm.startPrank(ownerProgram);
        loyaltyProgram.addLoyaltyGift(payable(address(mockLoyaltyGifts)), 0);
        vm.stopPrank(); 
    }

    function testLoyaltyGiftClaimCanBeRemoved() public {
        vm.startPrank(ownerProgram);
        loyaltyProgram.addLoyaltyGift(address(mockLoyaltyGifts), 0);
        loyaltyProgram.removeLoyaltyGiftClaimable(address(mockLoyaltyGifts), 0);
        vm.stopPrank();

        // Act / Assert
        assertEq(loyaltyProgram.getLoyaltyGiftIsClaimable(address(mockLoyaltyGifts), 0), false);
        assertEq(loyaltyProgram.getLoyaltyGiftIsRedeemable(address(mockLoyaltyGifts), 0), true);
    }

    function testLoyaltyGiftRedeemCanBeRemoved() public {
        vm.startPrank(ownerProgram);
        loyaltyProgram.addLoyaltyGift(address(mockLoyaltyGifts), 0);
        loyaltyProgram.removeLoyaltyGiftRedeemable(address(mockLoyaltyGifts), 0);
        vm.stopPrank();

        // Act / Assert
        assertEq(loyaltyProgram.getLoyaltyGiftIsClaimable(address(mockLoyaltyGifts), 0), false);
        assertEq(loyaltyProgram.getLoyaltyGiftIsRedeemable(address(mockLoyaltyGifts), 0), false);
    }

    // £todo this one currently fails with a [FAIL. Reason: log != expected log] error. Except... the log == log. Sort this out later.. 
    function testEmitsEventOnRemovingLoyaltyGiftClaim() public {
        // Arrange
        vm.prank(ownerProgram);
        loyaltyProgram.addLoyaltyGift(address(mockLoyaltyGifts), 0);

        vm.expectEmit(true, false, false, false, address(loyaltyProgram));
        emit RemovedLoyaltyGiftClaimable(address(mockLoyaltyGifts), 0);

        // Act / Assert
        vm.prank(ownerProgram);
        loyaltyProgram.removeLoyaltyGiftClaimable(address(mockLoyaltyGifts), 0);
    }

    // £todo this one currently fails with a [FAIL. Reason: log != expected log] error. Except... the log == log. Sort this out later.. 
    function testEmitsEventOnRemovingLoyaltyGiftRedeem() public {
        // Arrange
        vm.prank(ownerProgram);
        loyaltyProgram.addLoyaltyGift(address(mockLoyaltyGifts), 0);

        vm.expectEmit(true, false, false, false, address(loyaltyProgram));
        emit RemovedLoyaltyGiftRedeemable(address(mockLoyaltyGifts), 0);

        // Act / Assert
        vm.prank(ownerProgram);
        loyaltyProgram.removeLoyaltyGiftRedeemable(address(mockLoyaltyGifts), 0);
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
