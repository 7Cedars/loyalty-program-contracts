// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {MockLoyaltyGifts} from "../mocks/MockLoyaltyGifts.sol";
import {DeployLoyaltyProgram} from "../../script/DeployLoyaltyProgram.s.sol";
import {DeployMockLoyaltyGifts} from "../../script/DeployLoyaltyGifts.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC6551Registry} from "../../../test/mocks/MockERC6551Registry.t.sol";

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
    HelperConfig helperConfig;

    uint256[] GIFTS_TO_SELECT = [3, 5];
    uint256[] VOUCHERS_TO_MINT = [3, 5];
    uint256[] AMOUNT_VOUCHERS_TO_MINT = [24, 45];
    uint256[] GIFTS_TO_DESELECT = [3];

    function setUp() external {
        DeployLoyaltyProgram deployer = new DeployLoyaltyProgram();
        (loyaltyProgram, helperConfig) = deployer.run();
        DeployMockLoyaltyGifts giftDeployer = new DeployMockLoyaltyGifts();
        mockLoyaltyGifts = giftDeployer.run();
    }

    ///////////////////////////////////////////////
    ///          Minting Vouchers               ///
    ///////////////////////////////////////////////
    // NB! HERE ALSO WANT TO INSERT RANDOMISATION / FUZZINESS.

    function testLoyaltyProgramCanMintsVouchers() public {
        vm.startPrank(loyaltyProgram.getOwner());
        // 1st select gifts..
        for (uint256 i = 0; i < GIFTS_TO_SELECT.length; i++) {
            loyaltyProgram.addLoyaltyGift(address(mockLoyaltyGifts), GIFTS_TO_SELECT[i]);
        }

        // then mint gift vouchers..
        loyaltyProgram.mintLoyaltyVouchers(address(mockLoyaltyGifts), VOUCHERS_TO_MINT, AMOUNT_VOUCHERS_TO_MINT);
        vm.stopPrank();

        assertEq(mockLoyaltyGifts.balanceOf(address(loyaltyProgram), VOUCHERS_TO_MINT[0]), AMOUNT_VOUCHERS_TO_MINT[0]);
    }

    // This one does not pass yet for some reason..
    function testMintingVouchersEmitsEvent() public {
        vm.startPrank(loyaltyProgram.getOwner());
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

        vm.prank(loyaltyProgram.getOwner());
        loyaltyProgram.mintLoyaltyVouchers(address(mockLoyaltyGifts), VOUCHERS_TO_MINT, AMOUNT_VOUCHERS_TO_MINT);
    }
}
