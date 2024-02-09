// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {LoyaltyGift} from "../mocks/LoyaltyGift.sol";
import {DeployLoyaltyGift} from "../../script/DeployLoyaltyGifts.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

/**
 * @title Unit tests for LoyaltyGift Contract
 * @author Seven Cedars
 * @notice Tests are intentionally kept very simple.
 * Fuzziness is introduced in integration tests.
 */

contract LoyaltyGiftTest is Test {
    /**
     * events
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values
    );
    event LoyaltyGiftDeployed(address indexed issuer, uint256[] tokenised);

    uint256 keyZero = vm.envUint("DEFAULT_ANVIL_KEY_0");
    address addressZero = vm.addr(keyZero);
    uint256 keyOne = vm.envUint("DEFAULT_ANVIL_KEY_1");
    address addressOne = vm.addr(keyOne);

    string GIFT_URI =
        "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmSshfobzx5jtA14xd7zJ1PtmG8xFaPkAq2DZQagiAkSET/{id}";
    uint256[] TOKENISED = [0, 1];
    uint256[] VOUCHERS_TO_MINT = [1];
    uint256[] AMOUNT_VOUCHERS_TO_MINT = [24];
    uint256[] NON_TOKENISED_TO_MINT = [0];
    uint256[] AMOUNT_NON_TOKENISED_TO_MINT = [1];

    ///////////////////////////////////////////////
    ///                   Setup                 ///
    ///////////////////////////////////////////////

    LoyaltyGift loyaltyGift;

    function setUp() external {
        DeployLoyaltyGift deployer = new DeployLoyaltyGift();
        loyaltyGift = deployer.run();
    }

    function testLoyaltyGiftHasTokenised() public {
        uint256[] memory tokenised = loyaltyGift.getTokenised();
        assertNotEq(tokenised.length, 0);
    }

    function testRequirementsReturnsTrue() public {
        bool result = loyaltyGift.requirementsLoyaltyGiftMet(address(0), 0, 0);
        assertEq(result, true);
    }

    function testDeployEmitsevent() public {
        vm.expectEmit(true, false, false, false);
        emit LoyaltyGiftDeployed(addressZero, TOKENISED);

        vm.prank(addressZero);
        loyaltyGift = new LoyaltyGift(
        GIFT_URI,  
        TOKENISED
        );
    }

    ///////////////////////////////////////////////
    ///        Minting token / vouchers         ///
    ///////////////////////////////////////////////
    function testLoyaltyVouchersCanBeMinted() public {
        vm.prank(addressZero);
        loyaltyGift.mintLoyaltyVouchers(VOUCHERS_TO_MINT, AMOUNT_VOUCHERS_TO_MINT);

        assertEq(loyaltyGift.balanceOf(addressZero, VOUCHERS_TO_MINT[0]), AMOUNT_VOUCHERS_TO_MINT[0]);
    }

    function testMintingVouchersEmitsEvent() public {
        vm.expectEmit(true, false, false, false, address(loyaltyGift));
        emit TransferSingle(
            addressZero, // address indexed operator,
            address(0), // address indexed from,
            addressZero, // address indexed to,
            VOUCHERS_TO_MINT[0],
            AMOUNT_VOUCHERS_TO_MINT[0]
        );

        vm.prank(addressZero);
        loyaltyGift.mintLoyaltyVouchers(VOUCHERS_TO_MINT, AMOUNT_VOUCHERS_TO_MINT);
    }

    function testMintingVouchersRevertsIfGiftNotTokenised() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                LoyaltyGift.LoyaltyGift__NotTokenised.selector, address(loyaltyGift), NON_TOKENISED_TO_MINT[0]
            )
        );

        vm.prank(addressZero);
        loyaltyGift.mintLoyaltyVouchers(NON_TOKENISED_TO_MINT, AMOUNT_NON_TOKENISED_TO_MINT);
    }

    ///////////////////////////////////////////////
    ///            Issuing gifts                ///
    ///////////////////////////////////////////////
    function testReturnsTrueForSuccess() public {
        vm.startPrank(addressZero);
        loyaltyGift.mintLoyaltyVouchers(VOUCHERS_TO_MINT, AMOUNT_VOUCHERS_TO_MINT);
        
        bool result = loyaltyGift.requirementsLoyaltyGiftMet(addressOne, VOUCHERS_TO_MINT[0], 0);
        
        vm.stopPrank();

        assertEq(result, true);
    }

    function testIssueVoucherRevertsForNonAvailableTokenisedGift() public {
        vm.expectRevert(
            abi.encodeWithSelector(LoyaltyGift.LoyaltyGift__NoTokensAvailable.selector, address(loyaltyGift))
        );
        loyaltyGift.issueLoyaltyVoucher(addressOne, 1);
    }

    ///////////////////////////////////////////////
    ///    Reclaiming Tokens (vouchers)         ///
    ///////////////////////////////////////////////
    function testRedeemRevertsForNonAvailableTokenisedGift() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                LoyaltyGift.LoyaltyGift__NotTokenised.selector, address(loyaltyGift), NON_TOKENISED_TO_MINT[0]
            )
        );
        vm.prank(addressZero);
        loyaltyGift.redeemLoyaltyVoucher(address(0), NON_TOKENISED_TO_MINT[0]);
    }

    // For further testing, see interaction tests.
}
