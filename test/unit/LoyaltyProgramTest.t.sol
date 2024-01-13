// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LoyaltyProgramTest is Test {
    /* events */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event AddedLoyaltyTokenContract(address indexed loyaltyToken);
    event RemovedLoyaltyTokenClaimable(address indexed loyaltyToken);

    ///////////////////////////////////////////////
    ///                   Setup                 ///
    ///////////////////////////////////////////////

    LoyaltyProgram loyaltyProgramA;
    LoyaltyProgram loyaltyProgramB;
    HelperConfig helperConfig;
    uint256 minCustomerInteractions;
    uint256 maxCustomerInteractions;
    uint256 minPointsPerInteraction;
    uint256 maxPointsPerInteraction;

    struct Transaction {
        uint256 points;
        uint256 timestamp;
        bool redeemed;
    }

    address public vendorA;
    address public vendorB;
    address public customerOne = makeAddr("customer1");
    address public customerTwo = makeAddr("customer2");
    address public customerThree = makeAddr("customer3");
    address public loyaltyTokenContractA = makeAddr("loyaltyTokenA");
    address public loyaltyTokenContractB = makeAddr("loyaltyTokenB");
    address cardOneProgramA;
    address cardTwoProgramA;
    address cardOneProgramB;
    address cardTwoProgramB;

    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    /**
     * @dev this modifier sets up a fuzzy context consisting of
     * - 2 customers,
     */
    modifier setUpContext() 
    // uint256 random1,
    // uint256 random2,
    // uint256 random3
    {
        // transfer single loyalty card to customers
        vm.prank(vendorA);
        loyaltyProgramA.safeTransferFrom(vendorA, customerOne, 1, 1, "");
        vm.prank(vendorA);
        loyaltyProgramA.safeTransferFrom(vendorA, customerTwo, 2, 1, "");
        vm.prank(vendorB);
        loyaltyProgramB.safeTransferFrom(vendorB, customerTwo, 1, 1, "");
        vm.prank(vendorB);
        loyaltyProgramB.safeTransferFrom(vendorB, customerThree, 2, 1, "");

        vm.prank(vendorA);
        loyaltyProgramA.safeTransferFrom(vendorA, cardOneProgramA, 0, 200, "");
        vm.prank(vendorA);
        loyaltyProgramA.safeTransferFrom(vendorA, cardTwoProgramA, 0, 400, "");
        vm.prank(vendorB);
        loyaltyProgramB.safeTransferFrom(vendorB, cardOneProgramB, 0, 250, "");
        vm.prank(vendorB);
        loyaltyProgramB.safeTransferFrom(vendorB, cardTwoProgramB, 0, 555, "");
        _;
    }

    function setUp() external {
        DeployLoyaltyProgram deployer = new DeployLoyaltyProgram();
        loyaltyProgramA = deployer.run();
        loyaltyProgramB = deployer.run();

        vendorA = loyaltyProgramA.getOwner();
        vendorB = loyaltyProgramB.getOwner();

        // minting loyalty cards and points by vendors
        vm.prank(vendorA);
        loyaltyProgramA.mintLoyaltyCards(3);
        vm.prank(vendorA);
        loyaltyProgramA.mintLoyaltyPoints(500000);
        vm.prank(vendorB);
        loyaltyProgramB.mintLoyaltyCards(7);
        vm.prank(vendorB);
        loyaltyProgramB.mintLoyaltyPoints(1500000);

        // getting addresses of tokenBoundAccounts
        cardOneProgramA = loyaltyProgramA.getTokenBoundAddress(1);
        cardTwoProgramA = loyaltyProgramA.getTokenBoundAddress(2);
        cardOneProgramB = loyaltyProgramB.getTokenBoundAddress(1);
        cardTwoProgramB = loyaltyProgramB.getTokenBoundAddress(2);
    }

    function testLoyaltyProgramHasOwner() public {
        assertEq(vendorA, loyaltyProgramA.getOwner());
        assertEq(vendorB, loyaltyProgramB.getOwner());
    }

    ///////////////////////////////////////////////
    ///   Test Mint and Transfer LoyaltyCards   ///
    ///////////////////////////////////////////////

    function testOwnerCanMintLoyaltyCards(uint256 numberToMint) public {
        uint256 totalSupplyBefore;
        uint256 totalSupplyAfter;
        uint256 totalLoyaltyCardsMinted;
        uint256 i;

        numberToMint = bound(numberToMint, 1, 5);
        totalLoyaltyCardsMinted = loyaltyProgramA.getNumberLoyaltyCardsMinted();

        for (i = 1; i <= totalLoyaltyCardsMinted; i++) {
            totalSupplyBefore = totalSupplyBefore + loyaltyProgramA.balanceOf(vendorA, i);
        }

        // Act
        vm.prank(vendorA);
        loyaltyProgramA.mintLoyaltyCards(numberToMint);

        totalLoyaltyCardsMinted = loyaltyProgramA.getNumberLoyaltyCardsMinted();
        for (i = 1; i <= totalLoyaltyCardsMinted; i++) {
            totalSupplyAfter = totalSupplyAfter + loyaltyProgramA.balanceOf(vendorA, i);
        }

        // Assert
        assertEq(totalSupplyBefore + numberToMint, totalSupplyAfter);
    }

    function testOwnerCanTransferLoyaltyCards(uint256 idToTransfer) public setUpContext {
        uint256 i;
        vm.prank(vendorA); 
        loyaltyProgramA.mintLoyaltyPoints(1e25); 
        vm.prank(vendorA); 
        loyaltyProgramA.mintLoyaltyCards(50); 

        idToTransfer = bound(idToTransfer, 3, 5);

        for (i = 3; i <= idToTransfer; i++) {
            vm.prank(vendorA);
            loyaltyProgramA.safeTransferFrom(vendorA, customerOne, i, 1, "");
        }

        for (i = 3; i <= idToTransfer; i++) {
            assertEq(loyaltyProgramA.balanceOf(customerOne, i), 1);
        }
    }

    function testOwnerCannotTransferLoyaltyCardsItDoesNotOwn(uint256 numberToMint) public {
        address owner = loyaltyProgramA.getOwner();

        numberToMint = bound(numberToMint, 10, 50);
        vm.prank(loyaltyProgramA.getOwner());
        loyaltyProgramA.mintLoyaltyCards(numberToMint);

        uint256 numberLoyaltyCards = loyaltyProgramA.getNumberLoyaltyCardsMinted();

        vm.expectRevert();
        vm.prank(owner);
        loyaltyProgramA.safeTransferFrom(owner, customerOne, (numberLoyaltyCards + 5), 1, "");
    }

    //////////////////////////////////////////////////////
    ///     Test Mint, Gift, Transfer LoyaltyPoints    ///
    //////////////////////////////////////////////////////

    function testOwnerCanMintLoyaltyPoints(uint256 amount) public {
        uint256 totalSupplyBefore;
        uint256 totalSupplyAfter;

        amount = bound(amount, 10, 1e20);
        totalSupplyBefore = loyaltyProgramA.balanceOf(vendorA, 0);

        // Act
        vm.prank(vendorA);
        loyaltyProgramA.mintLoyaltyPoints(amount);
        totalSupplyAfter = loyaltyProgramA.balanceOf(vendorA, 0);

        // Assert
        assertEq(totalSupplyBefore + amount, totalSupplyAfter);
    }

    function testCustomerCannotMintLoyaltyPoints(uint256 amount) public {
        amount = bound(amount, 10, 1e20);

        // Act
        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__OnlyOwner.selector);
        vm.prank(customerOne);
        loyaltyProgramA.mintLoyaltyPoints(amount);
    }

    function testOwnerProgramCanTransferLoyaltyPoints(uint256 numberOfLoyaltyPoints) public setUpContext {
        uint256 balanceVendorA;
        uint256 balanceBefore;
        uint256 balanceAfter;

        balanceVendorA = loyaltyProgramA.balanceOf(vendorA, 0);
        numberOfLoyaltyPoints = bound(numberOfLoyaltyPoints, 0, balanceVendorA % 40);
        balanceBefore = loyaltyProgramA.getBalanceLoyaltyCard(1);

        console.log("vendorA: ", vendorA);
        address tokenAddress = loyaltyProgramA.getTokenBoundAddress(1);
        vm.prank(vendorA);
        loyaltyProgramA.safeTransferFrom(vendorA, tokenAddress, 0, numberOfLoyaltyPoints, "");
        balanceAfter = loyaltyProgramA.getBalanceLoyaltyCard(1);
        assertEq(balanceBefore + numberOfLoyaltyPoints, balanceAfter);
    }

    function testCannotTransferLoyaltyPointsToCustomer(uint256 numberOfLoyaltyPoints) public setUpContext {
        uint256 balanceVendorA = loyaltyProgramA.balanceOf(vendorA, 0);
        bound(numberOfLoyaltyPoints, 1, balanceVendorA / 4);

        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__TransferDenied.selector);
        vm.prank(vendorA);
        loyaltyProgramA.safeTransferFrom(vendorA, customerOne, 0, numberOfLoyaltyPoints, "");
    }

    /////////////////////////////////////////////////////
    /// Test Adding, Removing Loyalty Token Contracts ///
    /////////////////////////////////////////////////////

    function testOwnerCanAddLoyaltyTokenContract() public {
        // Act
        vm.prank(vendorB);
        loyaltyProgramB.addLoyaltyTokenContract(payable(loyaltyTokenContractA));

        // Assert
        assertEq(loyaltyProgramB.getLoyaltyTokensClaimable(loyaltyTokenContractA), 1);
        assertEq(loyaltyProgramB.getLoyaltyTokensClaimable(address(0)), 0);
    }

    function testEmitsEventOnAddingLoyaltyTokenContract() public {
        // Arrange
        vm.expectEmit(true, false, false, false, address(loyaltyProgramA));
        emit AddedLoyaltyTokenContract(loyaltyTokenContractA);
        // Act / Assert
        vm.prank(vendorA);
        loyaltyProgramA.addLoyaltyTokenContract(payable(loyaltyTokenContractA));
    }

    function testOwnerCanRemoveLoyaltyTokenContract() public {
        // Arrange
        vm.prank(vendorA);
        loyaltyProgramA.addLoyaltyTokenContract(payable(loyaltyTokenContractA));
        assertEq(loyaltyProgramA.getLoyaltyTokensClaimable(loyaltyTokenContractA), 1);

        // Act
        vm.prank(vendorA);
        loyaltyProgramA.removeLoyaltyTokenClaimable(loyaltyTokenContractA);

        // Assert
        assertEq(loyaltyProgramA.getLoyaltyTokensClaimable(loyaltyTokenContractA), 0);
    }

    function testEmitsEventOnRemovingloyaltyTokenContract() public {
        // Arrange
        vm.prank(vendorA);
        loyaltyProgramA.addLoyaltyTokenContract(payable(loyaltyTokenContractA));
        assertEq(loyaltyProgramA.getLoyaltyTokensClaimable(loyaltyTokenContractA), 1);

        vm.expectEmit(true, false, false, false, address(loyaltyProgramA));
        emit RemovedLoyaltyTokenClaimable(loyaltyTokenContractA);

        // Act / Assert
        vm.prank(vendorA);
        loyaltyProgramA.removeLoyaltyTokenClaimable(loyaltyTokenContractA);
    }

    function testCustomerCannotAddLoyaltyTokenContracts() public {
        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__OnlyOwner.selector);
        vm.prank(customerThree);
        loyaltyProgramA.addLoyaltyTokenContract(payable(loyaltyTokenContractA));

        console.log(address(vendorA));
        console.log(address(vendorB));
    }

    function testCustomerCannotRemoveLoyaltyTokenContracts() public {
        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__OnlyOwner.selector);
        vm.prank(customerTwo);
        loyaltyProgramB.removeLoyaltyTokenClaimable(loyaltyTokenContractB);
    }

    /////////////////////////////////////////////////////
    /////       Test claiming and redeeming Tokens  ///// 
    /////////////////////////////////////////////////////
    
    // function testLoyaltyCardCanExchangePointsForToken() public {
    //     // Arrange
    //     vm.prank(vendorA);
    //     loyaltyProgramA.addLoyaltyTokenContract(payable(loyaltyTokenContractA));
    //     vm.prank(vendorA);
    //     loyaltyProgramA.mintLoyaltyTokens(payable(loyaltyTokenContractA), 50);

    //     vm.prank(vendorA);
    //     loyaltyProgramA.safeTransferFrom(vendorA, customerOne, 2, 1, "");

    //     // Assert
    //     assertEq(loyaltyProgramA.getLoyaltyToken(loyaltyTokenContractA), 0);
    // }


}
