// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LoyaltyGift} from "./LoyaltyGift.sol";
import {ILoyaltyGift} from "../../src/interfaces/ILoyaltyGift.sol";
import {ERC1155} from "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Mock Loyalty Gifts
 * @author Seven Cedars
 * @notice A concrete implementation of a loyalty Gift contract. This contract simply exchanges loyalty points for three types of gifts and three types of vouchers.  
 */

contract MockLoyaltyGifts is LoyaltyGift {
    uint256[] public tokenised = [0, 0, 0, 1, 1, 1]; // 0 == false, 1 == true.

    
    /**
     * @notice constructor function: initiating loyalty gift contract. 
     * 
     * @dev the LoyaltyGift constructor takes to params: uri and tokenised (array denoting which gifts are - tokenised - vouchers.)
     * 
     */
    constructor()
        LoyaltyGift(
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmSshfobzx5jtA14xd7zJ1PtmG8xFaPkAq2DZQagiAkSET/{id}",
            tokenised
        )
    {}

    /**
     * @notice Sets requirement logics of tokens. Overrides function from the standard LoyaltyGift contract.
     * 
     * @param loyaltyCard loyalty card from which request is send. 
     * @param loyaltyGiftId loyalty gift requested
     * @param loyaltyPoints points to be sent. 
     * 
     * @dev This is the actual claim logic / price of the Loyalty Gift / Token
     * @dev Each gift can have its own bespoke logic.
     * @dev £todo This function should take calldata to make more diverse logics possible. 
     *  
     */
    function requirementsLoyaltyGiftMet(address loyaltyCard, uint256 loyaltyGiftId, uint256 loyaltyPoints)
        public
        override
        returns (bool success)
    {
        // loyalty gift 0: exchange 2500 points for immediate gift. 
        if (loyaltyGiftId == 0) {
            uint256 giftPriceInPoints = 2500;
            if (loyaltyPoints < giftPriceInPoints) {
                revert LoyaltyGift__RequirementsNotMet(address(this), loyaltyGiftId);
            }
        }

        // loyalty gift 1: exchange 4500 points for immediate gift. 
        if (loyaltyGiftId == 1) {
            uint256 giftPriceInPoints = 4500;
            if (loyaltyPoints < giftPriceInPoints) {
                revert LoyaltyGift__RequirementsNotMet(address(this), loyaltyGiftId);
            }
        }

        // loyalty gift 2: exchange 50000 points for immediate gift. 
        if (loyaltyGiftId == 2) {
            uint256 giftPriceInPoints = 50000;
            if (loyaltyPoints < giftPriceInPoints) {
                revert LoyaltyGift__RequirementsNotMet(address(this), loyaltyGiftId);
            }
        }

        // loyalty gift 3: exchange 2500 points for voucher. 
        if (loyaltyGiftId == 3) {
            uint256 giftPriceInPoints = 2500;
            if (loyaltyPoints < giftPriceInPoints) {
                revert LoyaltyGift__RequirementsNotMet(address(this), loyaltyGiftId);
            }
        }

        // loyalty gift 3: exchange 4500 points for voucher. 
        if (loyaltyGiftId == 4) {
            uint256 giftPriceInPoints = 4500;
            if (loyaltyPoints < giftPriceInPoints) {
                revert LoyaltyGift__RequirementsNotMet(address(this), loyaltyGiftId);
            }
        }

        // loyalty gift 3: exchange 50000 points for voucher. 
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
