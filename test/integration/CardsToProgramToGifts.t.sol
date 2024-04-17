// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {LoyaltyCard6551Account} from "../../src/LoyaltyCard6551Account.sol";
import {MockLoyaltyGift} from "../mocks/MockLoyaltyGift.sol";
import {MockLoyaltyGifts} from "../mocks/MockLoyaltyGifts.sol";

import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {DeployMockLoyaltyGifts} from "../../script/DeployLoyaltyGifts.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC6551Registry} from "../../test/mocks/ERC6551Registry.t.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title Intergation Test Loyalty Cards To Loyalty Programs to Loyalty Gifts  
 * @author Seven Cedars
 * @notice Integration tests
 * @dev For now I did not - at all - focus on efficiency and readability of this code. Focused on covering basic functions. 
 */

contract CardsToProgramToGiftsTest is Test {
    /* events */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /* Type declarations */
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    LoyaltyProgram loyaltyProgram;
    LoyaltyProgram alternativeLoyaltyProgram;
    MockLoyaltyGift loyaltyGift; 
    MockLoyaltyGifts mockLoyaltyGifts;
    HelperConfig helperConfig;
    LoyaltyCard6551Account loyaltyCardAccount; 
    address owner; 

    uint256 customerOneKey = 0xa11ce;
    uint256 customerTwoKey = 0x7ceda52;
    address customerOneAddress = vm.addr(customerOneKey);
    address customerTwoAddress = vm.addr(customerTwoKey);

    // EIP712 domain separator
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    // RequestGift message struct
    struct RequestGift {
        address from;
        address to;
        string gift;
        string cost;
        uint256 nonce;
    }

    // Redeem token message struct
    struct RedeemVoucher {
        address from;
        address to;
        string voucher;
        uint256 nonce;
    }

    // domain seperator.
    bytes32 internal DOMAIN_SEPARATOR; 

    ///////////////////////////////////////////////
    ///                   Setup                 ///
    ///////////////////////////////////////////////
    function setUp() external {
        // Deploy Loyalty and Gifts Program
        uint256[] memory giftIds = new uint256[](3); 
        giftIds[0] = 0; giftIds[1] = 3; giftIds[2] = 5; 
        uint256[] memory voucherIds = new uint256[](2); 
        voucherIds[0] = 3; voucherIds[1] = 5; 
        uint256[] memory amountVoucherIds = new uint256[](2);  
        amountVoucherIds[0] = 24; amountVoucherIds[1] = 45; 
        uint256[] memory cardIds = new uint256[](3); 
        cardIds[0] = 1; cardIds[1] = 2; cardIds[2] = 3; 
        uint256[] memory pointsToTransfer = new uint256[](3); 
        pointsToTransfer[0] = 10000; pointsToTransfer[1] = 12000; pointsToTransfer[1] = 14000; 

        uint256 pointsToMint = 500000000;
        uint256 cardsToMint = 3;

        DeployLoyaltyProgram deployer = new DeployLoyaltyProgram();
        (loyaltyProgram, helperConfig) = deployer.run();

        (alternativeLoyaltyProgram, ) = deployer.run();
        DeployMockLoyaltyGifts giftDeployer = new DeployMockLoyaltyGifts();
        mockLoyaltyGifts = giftDeployer.run();
        owner = loyaltyProgram.getOwner();
        address alternativeProgramOwner = alternativeLoyaltyProgram.getOwner();

        // an extensive interaction context needed in all tests below.
        // (hence no modifier used)
        vm.startPrank(owner);

        // Loyalty Program selecting Gifts
        for (uint256 i = 0; i < giftIds.length; i++) {
            loyaltyProgram.addLoyaltyGift(address(mockLoyaltyGifts), giftIds[i]);
        }

        // Loyalty Program minting Loyalty Points, Cards and Vouchers
        loyaltyProgram.mintLoyaltyPoints(pointsToMint);
        loyaltyProgram.mintLoyaltyCards(cardsToMint);
        loyaltyProgram.mintLoyaltyVouchers(address(mockLoyaltyGifts), voucherIds, amountVoucherIds);

        // Loyalty Program Transferring Points and vuchers to Cards
        for (uint256 i = 0; i < cardIds.length; i++) {
            loyaltyProgram.safeTransferFrom(
                owner, loyaltyProgram.getTokenBoundAddress(cardIds[i]), 0, pointsToTransfer[i], ""
            );
            loyaltyProgram.transferLoyaltyVoucher(
                owner, loyaltyProgram.getTokenBoundAddress(cardIds[i]), voucherIds[0], address(mockLoyaltyGifts)
                ); 
        }

        loyaltyProgram.safeTransferFrom(owner, customerOneAddress, 1, 1, "");
        vm.stopPrank();

        // Repeat these actions for alternative LoyaltyProgram. 
        vm.startPrank(alternativeProgramOwner);
        // Loyalty Program selecting Gifts
        for (uint256 i = 0; i < giftIds.length; i++) {
            alternativeLoyaltyProgram.addLoyaltyGift(address(mockLoyaltyGifts), giftIds[i]);
        }

        // Loyalty Program minting Loyalty Points, Cards and Vouchers
        alternativeLoyaltyProgram.mintLoyaltyPoints(pointsToMint);
        alternativeLoyaltyProgram.mintLoyaltyCards(cardsToMint);
        alternativeLoyaltyProgram.mintLoyaltyVouchers(address(mockLoyaltyGifts), voucherIds, amountVoucherIds);

        // Loyalty Program Transferring Points to Cards
        for (uint256 i = 0; i < cardIds.length; i++) {
            alternativeLoyaltyProgram.safeTransferFrom(
                alternativeProgramOwner, alternativeLoyaltyProgram.getTokenBoundAddress(cardIds[i]), 0, pointsToTransfer[i], ""
            );
        }

        alternativeLoyaltyProgram.safeTransferFrom(alternativeProgramOwner, customerOneAddress, 1, 1, "");
        vm.stopPrank(); 
    }

    ///////////////////////////////////////////////
    ///       Claiming Gifts and Voucher        ///
    ///////////////////////////////////////////////

    // claiming gift - happy path
    function testCustomerCanClaimGift() public {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address owner = loyaltyProgram.getOwner();
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request
        RequestGift memory message = RequestGift({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            gift: "This is a test gift",
            cost: "1500 points",
            nonce: 0
        });

        console.logUint(loyaltyProgram.getNonceLoyaltyCard(loyaltyCardOne));

        // customer signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message));
        console.logBytes32(digest);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // owner of loyaltyprogram uses signature when executing claimLoyaltyGift function.
        vm.prank(owner);
        loyaltyProgram.claimLoyaltyGift(
            "This is a test gift", // string memory _gift,
            "1500 points", // string memory _cost,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            4500, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );

        assertEq(mockLoyaltyGifts.balanceOf(loyaltyCardOne, giftId), 2);
    }

    function testClaimGiftRevertsWithInvalidKey() public {
        // PREPARE
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request..
        RequestGift memory message = RequestGift({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            gift: "This is a test gift",
            cost: "1500 points",
            nonce: 0
        });
        // .. & signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerTwoKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // EXPECT: revert.
        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__RequestInvalid.selector); //
        // ACT owner of loyaltyprogram uses signature when executing claimLoyaltyGift function.
        vm.prank(owner);
        loyaltyProgram.claimLoyaltyGift(
            "This is a test gift", // string memory _gift,
            "1500 points", // string memory _cost,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            4500, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );
    }


    function testClaimGiftRevertsIfNotOwnerLoyaltyCard() public {
        // PREPARE
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request..
        RequestGift memory message = RequestGift({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            gift: "This is a test gift",
            cost: "1500 points",
            nonce: 0
        });
        // .. & signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerTwoKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__NotOwnerLoyaltyCard.selector); // 
        vm.prank(owner);
        loyaltyProgram.claimLoyaltyGift(
            "This is a test gift", // string memory _gift,
            "1500 points", // string memory _cost,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerTwoAddress, // address customerAddress,
            4500, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );
    }

    function testClaimGiftRevertsIfAlreadyExecuted() public {
        // PREPARE
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request..
        RequestGift memory message = RequestGift({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            gift: "This is a test gift",
            cost: "1500 points",
            nonce: 0
        });
        // .. & signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(owner);
        loyaltyProgram.claimLoyaltyGift(
            "This is a test gift", // string memory _gift,
            "1500 points", // string memory _cost,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            4500, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );

        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__RequestAlreadyExecuted.selector); //  
        // ACT owner of executes request second time.
        vm.prank(owner);
        loyaltyProgram.claimLoyaltyGift(
            "This is a test gift", // string memory _gift,
            "1500 points", // string memory _cost,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            4500, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );
    }

    function testClaimGiftRevertsIfGiftNotClaimable() public {
        // PREPARE
        uint256 giftId = 2; // NOTICE: gift ID that has NOT been selected at setup.
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request..
        RequestGift memory message = RequestGift({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            gift: "This is a test gift",
            cost: "1500 points",
            nonce: 0
        });
        // .. & signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // EXPECT: revert.
        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__LoyaltyGiftInvalid.selector); //
        // ACT 
        vm.prank(owner);
        loyaltyProgram.claimLoyaltyGift(
            "This is a test gift", // string memory _gift,
            "1500 points", // string memory _cost,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            2500, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );
    }

    function testClaimGiftRevertsIfRequirementsNotMet() public {
        // PREPARE
        uint256 giftId = 3; 
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request..
        RequestGift memory message = RequestGift({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            gift: "This is a test gift",
            cost: "1500 points",
            nonce: 0
        });
        // .. & signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // EXPECT: revert.
        vm.expectRevert("Not enough points."); //
        // ACT 
        vm.prank(owner);
        loyaltyProgram.claimLoyaltyGift(
            "This is a test gift", // string memory _gift,
            "1500 points", // string memory _cost,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            25, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );
    }

    function testNonceUpdatedAfterSuccessfulClaim() public {
        // PREPARE
        uint256 giftId = 3; 
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request..
        RequestGift memory message = RequestGift({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            gift: "This is a test gift",
            cost: "1500 points",
            nonce: 0
        });
        // .. & signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // ACT 
        vm.prank(owner);
        loyaltyProgram.claimLoyaltyGift(
            "This is a test gift", // string memory _gift,
            "1500 points", // string memory _cost,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            4500, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );

        assertEq(loyaltyProgram.getNonceLoyaltyCard(loyaltyCardOne), 1);   
    }

    function testClaimGiftEmitsTransferSingleEventAtLoyaltyProgram() public {
        // PREPARE
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        uint256 loyaltyPoints = 4500;
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request..
        RequestGift memory message = RequestGift({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            gift: "This is a test gift",
            cost: "1500 points",
            nonce: 0
        });
        // .. & signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        //EXPECT: Emit transferSingle at LoyaltyProgram: gift is paid.
        vm.expectEmit(true, false, false, false);
        emit TransferSingle(
            owner, // address indexed operator,
            loyaltyCardOne, // address indexed from,
            owner, // address indexed to,
            0, // uint256 id,
            loyaltyPoints // uint256 value
        );

        // ACT owner of executes request second time.
        vm.prank(owner);
        loyaltyProgram.claimLoyaltyGift(
            "This is a test gift", // string memory _gift,
            "1500 points", // string memory _cost,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            loyaltyPoints, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );
    }


    ///////////////////////////////////////////////
    ///               Redeemt Voucher           ///
    ///////////////////////////////////////////////
    function testClaimGiftEmitsTransferSingleEventAtMockLoyaltyGiftsWhenVoucherisExchanged() public {
        // PREPARE
        uint256 giftId = 3; // NOTICE: this gift is a voucher.
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        uint256 loyaltyPoints = 4500;
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request..
        RequestGift memory message = RequestGift({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            gift: "This is a test gift",
            cost: "1500 points",
            nonce: 0
        });
        // .. & signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        //EXPECT: Emit transferSingle at LoyaltyProgram: Voucher exchanged
        vm.expectEmit(true, false, false, false);
        emit TransferSingle(
            address(loyaltyProgram), // address indexed operator,
            address(loyaltyProgram),
            loyaltyCardOne, // address indexed from,
            giftId, // uint256 id,
            1 // uint256 value
        );

        // ACT owner of executes request second time.
        vm.prank(owner);
        loyaltyProgram.claimLoyaltyGift(
            "This is a test gift", // string memory _gift,
            "1500 points", // string memory _cost,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            loyaltyPoints, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );
    }

    // redeeming voucher success - happy path.
    function testCustomerCanRedeemVoucher() public {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request
        RedeemVoucher memory message = RedeemVoucher({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            voucher: "This is a test redeem",
            nonce: 0
        });

        // customer signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRedeemVoucher(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // owner of loyaltyprogram uses signature when executing claimLoyaltyGift function.
        vm.prank(owner);
        loyaltyProgram.redeemLoyaltyVoucher(
            "This is a test redeem", // string memory _gift,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            signature // bytes memory signature
        );

        assertEq(mockLoyaltyGifts.balanceOf(loyaltyCardOne, giftId), 0);
    }

    // redeeming voucher reverts.
    function testRedeemVoucherRevertsWithInvalidSigner() public {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request
        RedeemVoucher memory message = RedeemVoucher({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            voucher: "This is a test redeem",
            nonce: 1
        });

        // customer signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRedeemVoucher(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerTwoKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // owner of loyaltyprogram uses signature when executing claimLoyaltyGift function.
        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__RequestInvalid.selector); //
        vm.prank(owner);
        loyaltyProgram.redeemLoyaltyVoucher(
            "This is a test redeem", // string memory _gift,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            signature // bytes memory signature
        );
    }

    function testRedeemVoucherRevertsIfSignerDoesNotOwnLoyaltyCard() public {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request
        RedeemVoucher memory message = RedeemVoucher({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            voucher: "This is a test redeem",
            nonce: 0
        });

        // customer signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRedeemVoucher(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerTwoKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // owner of loyaltyprogram uses signature when executing claimLoyaltyGift function.
        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__NotOwnerLoyaltyCard.selector); //
        vm.prank(owner);
        loyaltyProgram.redeemLoyaltyVoucher(
            "This is a test redeem", // string memory _gift,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, //  loyaltyCardId,
            customerTwoAddress, // address customerAddress,
            signature // bytes memory signature
        );
    }

    function testRedeemVoucherRevertsIfTokenNotRedeemable() public {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // removing voucher as being redeemable.
        vm.prank(owner);
        loyaltyProgram.removeLoyaltyGiftRedeemable(address(mockLoyaltyGifts), 3);

        // customer creates request
        RedeemVoucher memory message = RedeemVoucher({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            voucher: "This is a test redeem",
            nonce: 0
        });

        // customer signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRedeemVoucher(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // EXPECT
        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__LoyaltyVoucherInvalid.selector); //
        // ACT
        vm.prank(owner);
        loyaltyProgram.redeemLoyaltyVoucher(
            "This is a test redeem", // string memory _gift,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            signature // bytes memory signature
        );
    }

    // redeeming voucher event emits.
    function testRedeemVoucherEmitsTransferSingleEvent() public {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request
        RedeemVoucher memory message = RedeemVoucher({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            voucher: "This is a test redeem",
            nonce: 0
        });

        // customer signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRedeemVoucher(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, false, false, false);
        emit TransferSingle(
            address(loyaltyProgram), // address indexed operator,
            loyaltyCardOne, // address indexed from,
            address(loyaltyProgram), // address indexed to,
            giftId, // uint256 id
            1 // uint256 amount
        );

        // owner of loyaltyprogram uses signature when executing claimLoyaltyGift function.
        vm.prank(owner);
        loyaltyProgram.redeemLoyaltyVoucher(
            "This is a test redeem", // string memory _gift,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            signature // bytes memory signature
        );
    }

    //////////////////////////////////////////////////////
    ///    Transfer Checks Loyalty Gifts and Voucher   ///
    //////////////////////////////////////////////////////
    function testLoyaltyCardCannotClaimAtAnotherProgram() public {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        // = loyalty card from loyaltyProgram
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address alternativeProgramOwner = alternativeLoyaltyProgram.getOwner();
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request
        RequestGift memory message = RequestGift({
            from: loyaltyCardOne, // card from loyaltyProgram
            to: address(alternativeLoyaltyProgram), // trying to claim at _alternative_LoyaltyProgram. 
            gift: "This is a test gift",
            cost: "1500 points",
            nonce: 0
        });

        // customer signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message));
        console.logBytes32(digest);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // owner of loyaltyprogram uses signature when executing claimLoyaltyGift function.
        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__RequestInvalid.selector); // £todo specify later.
        vm.prank(alternativeProgramOwner);
        alternativeLoyaltyProgram.claimLoyaltyGift(
            "This is a test gift", // string memory _gift,
            "1500 points", // string memory _cost,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            4500, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );
    }

    function testVoucherCannotBeRedeemedAtAnotherProgram() public {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        // = loyalty card from loyaltyProgram
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address alternativeProgramOwner = alternativeLoyaltyProgram.getOwner();
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // customer creates request to _alternative_LoyaltyProgram
        // NB: all the same gifts have been activated - so voucher is also valid in alternativeLoyaltyProgram. 
        RedeemVoucher memory message = RedeemVoucher({
            from: loyaltyCardOne,
            to: address(alternativeLoyaltyProgram),
            voucher: "This is a test redeem",
            nonce: 1
        });

        // customer signs request
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRedeemVoucher(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(LoyaltyProgram.LoyaltyProgram__RequestInvalid.selector); 

        // owner of loyaltyprogram uses signature when executing claimLoyaltyGift function.
        vm.prank(alternativeProgramOwner);
        alternativeLoyaltyProgram.redeemLoyaltyVoucher(
            "This is a test redeem", // string memory _gift,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            signature // bytes memory signature
        );
    }

    function testVouchersCannotBeTransferredBetweenLoyaltyCards() public {
        uint256 giftId = 3;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address loyaltyCardTwo = loyaltyProgram.getTokenBoundAddress(2);
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        vm.expectRevert(); 
        // vm.expectRevert(
        //     abi.encodeWithSelector(LoyaltyGift.LoyaltyGift__TransferDenied.selector, address(mockLoyaltyGifts))
        // ); 
        vm.prank(customerOneAddress); 
        LoyaltyCard6551Account(payable(loyaltyCardOne)).execute(
                payable(address(mockLoyaltyGifts)),
                0,
                abi.encodeCall(
                    mockLoyaltyGifts.safeTransferFrom,
                    (loyaltyCardOne, loyaltyCardTwo, giftId, 1, "")
                ), 
                0
            );
    }

    // ///////////////////////////////////////////////
    // ///      Helper Functions Voucher           ///
    // ///////////////////////////////////////////////

    // helper function hashRequestGift
    function hashRequestGift(RequestGift memory message) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                // keccak256(bytes("RequestGift(uint256 nonce)")),
                keccak256(bytes("RequestGift(address from,address to,string gift,string cost,uint256 nonce)")),
                message.from,
                message.to,
                keccak256(bytes(message.gift)),
                keccak256(bytes(message.cost)),
                message.nonce
            )
        );
    }

    // helper function hashRedeemVoucher
    function hashRedeemVoucher(RedeemVoucher memory message) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(bytes("RedeemVoucher(address from,address to,string voucher,uint256 nonce)")),
                message.from,
                message.to,
                keccak256(bytes(message.voucher)),
                message.nonce
            )
        );
    }

    // helper function separator
    function hashDomainSeparator () public view returns (bytes32) {
        
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Loyalty Program")), // name
                keccak256(bytes("1")), // version
                block.chainid, // chainId
                loyaltyProgram //  0xBb2180ebd78ce97360503434eD37fcf4a1Df61c3 // verifyingContract
            )
        );
    }


}

// NB: docs on console.logging:  https://book.getfoundry.sh/reference/forge-std/console-log?highlight=console.loguint#console-logging

//     function testCustomerCannotMintLoyaltyPoints(uint256 amount) public {
//         amount = bound(amount, 10, 1e20);

//         // Act
//         vm.expectRevert(LoyaltyProgram.LoyaltyProgram__OnlyOwner.selector);
//         vm.prank(customerOne);
//         loyaltyProgramA.mintLoyaltyPoints(amount);
//     }
