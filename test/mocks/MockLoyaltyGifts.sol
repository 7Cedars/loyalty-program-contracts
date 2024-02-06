// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LoyaltyGift} from "./LoyaltyGift.sol";
import {ILoyaltyGift} from "../../src/interfaces/ILoyaltyGift.sol";
import {ERC1155} from "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

/**
 * @dev
 */
contract MockLoyaltyGifts is LoyaltyGift {
    uint256[] public tokenised = [0, 0, 0, 1, 1, 1]; // 0 == false, 1 == true.

    /**
     * @dev
     */
    constructor()
        LoyaltyGift(
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmSshfobzx5jtA14xd7zJ1PtmG8xFaPkAq2DZQagiAkSET/{id}",
            tokenised
        )
    {}

    /**
     * @dev This is the actual claim logic / price of the Loyalty Gift / Token
     * Each gift can have its own bespoke logic.
     */
    function requirementsLoyaltyGiftMet(address loyaltyCard, uint256 loyaltyGiftId, uint256 loyaltyPoints)
        public
        override
        returns (bool success)
    {
        if (loyaltyGiftId == 0) {
            uint256 giftPriceInPoints = 2500;
            if (loyaltyPoints < giftPriceInPoints) {
                revert LoyaltyGift__RequirementsNotMet(address(this), loyaltyGiftId);
            }
        }

        if (loyaltyGiftId == 1) {
            uint256 giftPriceInPoints = 4500;
            if (loyaltyPoints < giftPriceInPoints) {
                revert LoyaltyGift__RequirementsNotMet(address(this), loyaltyGiftId);
            }
        }

        if (loyaltyGiftId == 2) {
            uint256 giftPriceInPoints = 50000;
            if (loyaltyPoints < giftPriceInPoints) {
                revert LoyaltyGift__RequirementsNotMet(address(this), loyaltyGiftId);
            }
        }

        if (loyaltyGiftId == 3) {
            uint256 giftPriceInPoints = 2500;
            if (loyaltyPoints < giftPriceInPoints) {
                revert LoyaltyGift__RequirementsNotMet(address(this), loyaltyGiftId);
            }
        }

        if (loyaltyGiftId == 4) {
            uint256 giftPriceInPoints = 4500;
            if (loyaltyPoints < giftPriceInPoints) {
                revert LoyaltyGift__RequirementsNotMet(address(this), loyaltyGiftId);
            }
        }

        if (loyaltyGiftId == 5) {
            uint256 giftPriceInPoints = 50000;
            if (loyaltyPoints < giftPriceInPoints) {
                revert LoyaltyGift__RequirementsNotMet(address(this), loyaltyGiftId);
            }
        }

        bool check = super.requirementsLoyaltyGiftMet(loyaltyCard, loyaltyGiftId, loyaltyPoints);
        return check;
    }
}
