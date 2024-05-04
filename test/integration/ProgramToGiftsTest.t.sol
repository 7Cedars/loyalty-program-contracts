// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {MockLoyaltyGifts} from "../mocks/MockLoyaltyGifts.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {DeployMockLoyaltyGifts} from "../../script/DeployLoyaltyGifts.s.sol";
import {ERC6551Registry} from "../../test/mocks/ERC6551Registry.t.sol";

contract ProgramToGiftsTest is Test {
    /* events */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values
    );
    event AddedLoyaltyGift(address indexed loyaltyGift, uint256 loyaltyGiftId);

    ///////////////////////////////////////////////
    ///                   Setup                 ///
    ///////////////////////////////////////////////

    LoyaltyProgram loyaltyProgram;
    MockLoyaltyGifts mockLoyaltyGifts;
    address programOwner; 

    uint256[] GIFTS_TO_SELECT = [3, 5];
    uint256[] VOUCHERS_TO_MINT = [3, 5];
    uint256[] AMOUNT_VOUCHERS_TO_MINT = [24, 45];
    uint256[] GIFTS_TO_DESELECT = [3];
    
    uint256 customerOneKey = 0x7ceda52;
    address customerOneAddress = vm.addr(customerOneKey);

    function setUp() external {
        string memory rpc_url = vm.envString("SELECTED_RPC_URL"); 
        uint256 forkId = vm.createFork(rpc_url);
        vm.selectFork(forkId);
        
        DeployLoyaltyProgram deployer = new DeployLoyaltyProgram();
        loyaltyProgram = deployer.run();
        programOwner = loyaltyProgram.getOwner(); 

        DeployMockLoyaltyGifts giftDeployer = new DeployMockLoyaltyGifts();
        mockLoyaltyGifts = giftDeployer.run();
    }

    ///////////////////////////////////////////////
    ///          Minting Vouchers               ///
    ///////////////////////////////////////////////

    function testLoyaltyProgramCanMintsVouchers() public {
        vm.startPrank(programOwner);
        // 1st select gifts..
        for (uint256 i = 0; i < GIFTS_TO_SELECT.length; i++) {
            loyaltyProgram.addLoyaltyGift(address(mockLoyaltyGifts), GIFTS_TO_SELECT[i]);
        }

        // then mint gift vouchers..
        loyaltyProgram.mintLoyaltyVouchers(address(mockLoyaltyGifts), VOUCHERS_TO_MINT, AMOUNT_VOUCHERS_TO_MINT);
        vm.stopPrank();

        assertEq(mockLoyaltyGifts.balanceOf(programOwner, VOUCHERS_TO_MINT[0]), AMOUNT_VOUCHERS_TO_MINT[0]);
    }

    function testMintingVouchersEmitsEvent() public {
        vm.startPrank(programOwner);
        // 1st select gifts..
        for (uint256 i = 0; i < GIFTS_TO_SELECT.length; i++) {
            loyaltyProgram.addLoyaltyGift(address(mockLoyaltyGifts), GIFTS_TO_SELECT[i]);
        }
        vm.stopPrank();

        vm.expectEmit(true, false, false, false, address(mockLoyaltyGifts));
        emit TransferBatch(
            address(loyaltyProgram), // address indexed operator,
            address(0), // address indexed from,
            address(loyaltyProgram), // address indexed to,
            VOUCHERS_TO_MINT,
            AMOUNT_VOUCHERS_TO_MINT
        );

        vm.prank(programOwner);
        loyaltyProgram.mintLoyaltyVouchers(address(mockLoyaltyGifts), VOUCHERS_TO_MINT, AMOUNT_VOUCHERS_TO_MINT);
    }

    ///////////////////////////////////////////////
    ///           Transferring Voucher          ///
    ///////////////////////////////////////////////
    function testOwnerCanTransferVoucherToLoyaltyCard() public {
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(loyaltyCardId);

        vm.startPrank(programOwner); 
        loyaltyProgram.mintLoyaltyVouchers(address(mockLoyaltyGifts), VOUCHERS_TO_MINT, AMOUNT_VOUCHERS_TO_MINT);
        loyaltyProgram.transferLoyaltyVoucher(
            programOwner, 
            loyaltyCardOne, 
            address(mockLoyaltyGifts), 
            VOUCHERS_TO_MINT[0]
        ); 
        vm.stopPrank(); 

        assertEq(mockLoyaltyGifts.balanceOf(loyaltyCardOne, VOUCHERS_TO_MINT[0]), 1); 
    }

    function testLoyaltyCardCanTransferVoucherToOwner() public {
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(loyaltyCardId);

        // first transfer voucher to loyalty Card... 
        vm.startPrank(programOwner); 
        loyaltyProgram.mintLoyaltyVouchers(address(mockLoyaltyGifts), VOUCHERS_TO_MINT, AMOUNT_VOUCHERS_TO_MINT);
        loyaltyProgram.transferLoyaltyVoucher(
            programOwner, 
            loyaltyCardOne, 
            address(mockLoyaltyGifts),
            VOUCHERS_TO_MINT[0]
        ); 
        vm.stopPrank(); 
        assertEq(mockLoyaltyGifts.balanceOf(loyaltyCardOne, VOUCHERS_TO_MINT[0]), 1); 
        
        // and then transfer voucher back to owner... 
        vm.prank(customerOneAddress); 
        loyaltyProgram.transferLoyaltyVoucher(
            loyaltyCardOne, 
            programOwner, 
            address(mockLoyaltyGifts), 
            VOUCHERS_TO_MINT[0]
        ); 
        assertEq(mockLoyaltyGifts.balanceOf(loyaltyCardOne, VOUCHERS_TO_MINT[0]), 0); 
    }

    // owner cannot call transfer directly on loyaltyGift. 
    function testVouchersCannotBeTransferredCiaGiftContract() public {
        uint256 loyaltyCardId = 1;
        address loyaltyCardOne = loyaltyProgram.getTokenBoundAddress(loyaltyCardId);

        vm.expectRevert();  
        vm.startPrank(programOwner); 
        mockLoyaltyGifts.safeTransferFrom(
            programOwner, 
            loyaltyCardOne, 
            VOUCHERS_TO_MINT[0], 
            1, 
            ""
        ); 
        vm.stopPrank(); 
    }
}
