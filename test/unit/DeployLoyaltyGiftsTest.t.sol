// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployMockLoyaltyGifts} from "../../script/DeployLoyaltyGifts.s.sol";
import {MockLoyaltyGifts} from "../mocks/MockLoyaltyGifts.sol";
 import {MockLoyaltyGift} from "../mocks/MockLoyaltyGift.sol";

contract DeployMockLoyaltyGiftsTest is Test {
    DeployMockLoyaltyGifts public deployer;
    address public vendorOne = makeAddr("vendor1");
    uint256[] VOUCHERS_TO_MINT = [3];
    uint256[] AMOUNT_VOUCHERS_TO_MINT = [24];

    function setUp() public {
        deployer = new DeployMockLoyaltyGifts();
    }

    function testNameDeployedLoyaltyGiftIsCorrect() public {
        MockLoyaltyGifts mockLoyaltyGifts = deployer.run();

        string memory expectedUri =
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmXS9s48RkDDDSqsyjBHN9HRSXpUud3FsBDVa1uZjXYMAH/{id}";
        vm.prank(vendorOne);
        mockLoyaltyGifts.mintLoyaltyVouchers(VOUCHERS_TO_MINT, AMOUNT_VOUCHERS_TO_MINT);
        string memory actualUri = mockLoyaltyGifts.uri(1);
        assert(keccak256(abi.encodePacked(expectedUri)) == keccak256(abi.encodePacked(actualUri)));
    }
}
