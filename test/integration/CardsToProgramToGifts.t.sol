// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {LoyaltyCard6551Account} from "../../src/LoyaltyCard6551Account.sol";
import {LoyaltyGift} from "../mocks/LoyaltyGift.sol";
import {MockLoyaltyGifts} from "../mocks/MockLoyaltyGifts.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {DeployMockLoyaltyGifts} from "../../script/DeployLoyaltyGifts.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC6551Registry} from "../mocks/ERC6551Registry.sol";
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
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values
    );

    /* Type declarations */
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    LoyaltyProgram loyaltyProgram;
    LoyaltyProgram alternativeLoyaltyProgram;
    LoyaltyGift loyaltyGift; 
    MockLoyaltyGifts mockLoyaltyGifts;
    HelperConfig helperConfig;
    LoyaltyCard6551Account loyaltyCardAccount; 

    uint256[] GIFTS_TO_SELECT = [0, 3, 5];
    uint256[] VOUCHERS_TO_MINT = [3, 5];
    uint256[] AMOUNT_VOUCHERS_TO_MINT = [24, 45];
    uint256[] GIFTS_TO_DESELECT = [3];
    uint256 CARDS_TO_MINT = 3;
    uint256[] CARD_IDS = [1, 2, 3];
    uint256[] CARDS_SINGLES = [1, 1, 1];
    uint256 POINTS_TO_MINT = 500000000;
    uint256[] POINTS_TO_TRANSFER = [10000, 12000, 14000];
    uint256 SALT_TOKEN_BASED_ACCOUNT = 3947539732098357;

    uint256 customerOneKey = 0xa11ce;
    uint256 customerTwoKey = 0x7ceda5;
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
    //  = keccak256(
    //     abi.encode(
    //         keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
    //         keccak256(bytes("Loyalty Program")), // name
    //         keccak256(bytes("1")), // version
    //         block.chainid, // chainId
    //         address(loyaltyProgram) //  0xBb2180ebd78ce97360503434eD37fcf4a1Df61c3 // verifyingContract
    //     )
    // );

    // this modifier gives one voucher to CustomerCard1 owned by customerOne.
    modifier giftClaimedAndVoucherReceived() {
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
            2500, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );

        _;
    }

    ///////////////////////////////////////////////
    ///                   Setup                 ///
    ///////////////////////////////////////////////
    function setUp() external {
        // Deploy Loyalty and Gifts Program

        DeployLoyaltyProgram deployer = new DeployLoyaltyProgram();
        (loyaltyProgram, helperConfig) = deployer.run();
        (alternativeLoyaltyProgram, ) = deployer.run();
        DeployMockLoyaltyGifts giftDeployer = new DeployMockLoyaltyGifts();
        mockLoyaltyGifts = giftDeployer.run();
        address owner = loyaltyProgram.getOwner();
        address alternativeOwner = alternativeLoyaltyProgram.getOwner();

        // an extensive interaction context needed in all tests below.
        // (hence no modifier used)
        vm.startPrank(owner);

        // Loyalty Program selecting Gifts
        for (uint256 i = 0; i < GIFTS_TO_SELECT.length; i++) {
            loyaltyProgram.addLoyaltyGift(address(mockLoyaltyGifts), GIFTS_TO_SELECT[i]);
        }

        // Loyalty Program minting Loyalty Points, Cards and Vouchers
        loyaltyProgram.mintLoyaltyPoints(POINTS_TO_MINT);
        loyaltyProgram.mintLoyaltyCards(CARDS_TO_MINT);
        loyaltyProgram.mintLoyaltyVouchers(address(mockLoyaltyGifts), VOUCHERS_TO_MINT, AMOUNT_VOUCHERS_TO_MINT);

        // Loyalty Program Transferring Points to Cards
        for (uint256 i = 0; i < CARD_IDS.length; i++) {
            loyaltyProgram.safeTransferFrom(
                owner, loyaltyProgram.getTokenBoundAddress(CARD_IDS[i]), 0, POINTS_TO_TRANSFER[i], ""
            );
        }

        loyaltyProgram.safeTransferFrom(owner, customerOneAddress, 1, 1, "");
        vm.stopPrank();

        // Repeat these actions for alternative LoyaltyProgram. 
        vm.startPrank(alternativeOwner);
        // Loyalty Program selecting Gifts
        for (uint256 i = 0; i < GIFTS_TO_SELECT.length; i++) {
            alternativeLoyaltyProgram.addLoyaltyGift(address(mockLoyaltyGifts), GIFTS_TO_SELECT[i]);
        }

        // Loyalty Program minting Loyalty Points, Cards and Vouchers
        alternativeLoyaltyProgram.mintLoyaltyPoints(POINTS_TO_MINT);
        alternativeLoyaltyProgram.mintLoyaltyCards(CARDS_TO_MINT);
        alternativeLoyaltyProgram.mintLoyaltyVouchers(address(mockLoyaltyGifts), VOUCHERS_TO_MINT, AMOUNT_VOUCHERS_TO_MINT);

        // Loyalty Program Transferring Points to Cards
        for (uint256 i = 0; i < CARD_IDS.length; i++) {
            alternativeLoyaltyProgram.safeTransferFrom(
                alternativeOwner, alternativeLoyaltyProgram.getTokenBoundAddress(CARD_IDS[i]), 0, POINTS_TO_TRANSFER[i], ""
            );
        }

        alternativeLoyaltyProgram.safeTransferFrom(alternativeOwner, customerOneAddress, 1, 1, "");
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
            2500, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );

        assertEq(mockLoyaltyGifts.balanceOf(loyaltyCardOne, giftId), 1);
    }

    function testClaimGiftRevertsWithInvalidKey() public {
        // PREPARE
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address owner = loyaltyProgram.getOwner();
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
            2500, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );
    }

    function testClaimGiftRevertsIfAlreadyExecuted() public {
        // PREPARE
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address owner = loyaltyProgram.getOwner();
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
            2500, // uint256 loyaltyPoints,
            signature // bytes memory signature
        );

        // EXPECT: revert. This actually reverts with a RequestInvalid because the nonce is incorrect.
        vm.expectRevert(); //  LoyaltyProgram.LoyaltyProgram__RequestAlreadyExecuted.selector
        // ACT owner of executes request second time.
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

    function testClaimGiftRevertsIfGiftNotClaimable() public {
        // PREPARE
        uint256 giftId = 2; // NOTICE: gift ID that has NOT been selected at setup.
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address owner = loyaltyProgram.getOwner();
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
        // ACT owner of executes request second time.
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

    function testClaimGiftEmitsTransferSingleEventAtLoyaltyProgram() public {
        // PREPARE
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address owner = loyaltyProgram.getOwner();
        uint256 loyaltyPoints = 2500;
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

    function testClaimGiftEmitsTransferSingleEventAtMockLoyaltyGiftsWhenVoucherisExchanged() public {
        // PREPARE
        uint256 giftId = 3; // NOTICE: this gift is a voucher.
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address owner = loyaltyProgram.getOwner();
        uint256 loyaltyPoints = 2500;
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

    ///////////////////////////////////////////////
    ///               Redeemt Voucher           ///
    ///////////////////////////////////////////////

    // redeeming voucher success - happy path.
    function testCustomerCanRedeemVoucher() public giftClaimedAndVoucherReceived {
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
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(customerOneKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // owner of loyaltyprogram uses signature when executing claimLoyaltyGift function.
        vm.prank(loyaltyProgram.getOwner());
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
    function testRedeemVoucherRevertsWithInvalidSigner() public giftClaimedAndVoucherReceived {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address owner = loyaltyProgram.getOwner();
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

    function testRedeemVoucherRevertsIfSignerDoesNotOwnLoyaltyCard() public giftClaimedAndVoucherReceived {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address owner = loyaltyProgram.getOwner();
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

    function testRedeemVoucherRevertsIfTokenNotRedeemable() public giftClaimedAndVoucherReceived {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address owner = loyaltyProgram.getOwner();
        DOMAIN_SEPARATOR = hashDomainSeparator(); 

        // removing voucher as being redeemable.
        vm.prank(owner);
        loyaltyProgram.removeLoyaltyGiftRedeemable(address(mockLoyaltyGifts), 3);

        // customer creates request
        RedeemVoucher memory message = RedeemVoucher({
            from: loyaltyCardOne,
            to: address(loyaltyProgram),
            voucher: "This is a test redeem",
            nonce: 1
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
    function testRedeemVoucherEmitsTransferSingleEvent() public giftClaimedAndVoucherReceived {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address owner = loyaltyProgram.getOwner();
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
        address alternativeOwner = alternativeLoyaltyProgram.getOwner();
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
        vm.prank(alternativeOwner);
        alternativeLoyaltyProgram.claimLoyaltyGift(
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

    function testVoucherCannotBeRedeemedAtAnotherProgram() public giftClaimedAndVoucherReceived {
        uint256 giftId = 3;
        uint256 loyaltyCardId = 1;
        // = loyalty card from loyaltyProgram
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(1);
        address alternativeOwner = alternativeLoyaltyProgram.getOwner();
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
        vm.prank(alternativeOwner);
        alternativeLoyaltyProgram.redeemLoyaltyVoucher(
            "This is a test redeem", // string memory _gift,
            address(mockLoyaltyGifts), // address loyaltyGiftsAddress,
            giftId, // uint256 loyaltyGiftId,
            loyaltyCardId, // address loyaltyCardAddress,
            customerOneAddress, // address customerAddress,
            signature // bytes memory signature
        );
    }

    function testVouchersCannotBeTransferredBetweenLoyaltyCards() public giftClaimedAndVoucherReceived {
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




    ///////////////////////////////////////////////
    ///      Helper Functions Voucher           ///
    ///////////////////////////////////////////////

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
