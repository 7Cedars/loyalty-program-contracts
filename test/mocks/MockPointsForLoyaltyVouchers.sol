// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LoyaltyGift} from "./LoyaltyGift.sol";
import {ILoyaltyGift} from "../../src/interfaces/ILoyaltyGift.sol";
import {ERC1155} from "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev THIS CONTRACT HAS NOT BEEN AUDITED. WORSE: TESTING IS INCOMPLETE. DO NOT DEPLOY ON ANYTHING ELSE THAN A TEST CHAIN! 
 * 
 * @title Points for Loyalty Vouchers
 * @author Seven Cedars
 * @notice A concrete implementation of a loyalty Gift contract. This contract simply exchanges loyalty points for three types of gifts and three types of vouchers.
 * 
 * For a mock version of the LoyalProgram contract these gifts interact with, see the test/mocks/test/mocks/MockLoyaltyProgram.sol. 
 * 
 */

contract PointsForLoyaltyVouchers is LoyaltyGift {
    Gift gift0 = Gift({
        claimable: true, 
        cost: 2500, 
        additionalRequirements: false, 
        voucher: true 
        }); 
    Gift gift1 = Gift({
        claimable: true, 
        cost: 4500, 
        additionalRequirements: false, 
        voucher: true 
        }); 
    Gift gift2 = Gift({
        claimable: true, 
        cost: 50000, 
        additionalRequirements: false, 
        voucher: true 
        }); 

    Gift[] public gifts = [gift0, gift1, gift2];  

    /**
     * @notice constructor function: initiating loyalty gift contract. 
     * 
     * @dev the LoyaltyGift constructor takes to params: uri and tokenised (array denoting which gifts are - tokenised - vouchers.)
     * £todo URI STILL NEEDS TO BE CHANGED! 
     */
    constructor()
        LoyaltyGift(
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmXS9s48RkDDDSqsyjBHN9HRSXpUud3FsBDVa1uZjXYMAH/{id}",
            gifts
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
        // loyalty gift 3: exchange 2500 points for voucher. 
        if (loyaltyGiftId == 0) {
            if (loyaltyPoints < gifts[0].costs) {
                revert ("Not enough points.");
            }
        }

        // loyalty gift 3: exchange 4500 points for voucher. 
        if (loyaltyGiftId == 1) {
            if (loyaltyPoints < gifts[1].costs) {
                revert ("Not enough points.");
            }
        }

        // loyalty gift 3: exchange 50000 points for voucher. 
        if (loyaltyGiftId == 2) {
            if (loyaltyPoints < gifts[2].costs) {
                revert ("Not enough points.");
            }
        }

        bool check = super.requirementsLoyaltyGiftMet(loyaltyCard, loyaltyGiftId, loyaltyPoints);
        return check;
    }
}
