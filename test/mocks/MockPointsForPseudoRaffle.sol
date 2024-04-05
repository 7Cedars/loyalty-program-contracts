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
 * @title Points for Pseudo Raffle 
 * @author Seven Cedars
 * @notice  This contract exchanges 1250 loyalty points for access to a raflle in which three gifts can be won: a coffee, donought and cupcake.
 * This raffle is not truly randomised and can easily be gamed. As such, it should only be used for raffles where gifts are relatively small and of equal value.  
 * 
 * @notice The contract is build as a single gift within a single contract, but that issues randomised vouchers when called. 
 * 
 * £todo: 
 * Upload images to pinata; create metadata files. 
 */

/////////////////////////////////////////
// EVERYTHIN BELOW IS STILL WIP / OLD! //
/////////////////////////////////////////

contract PointsForPseudoRaffle is LoyaltyGift {
    Gift raffleGift = Gift({
        claimable: true, 
        cost: 1250, 
        additionalRequirements: false, 
        voucher: false 
        }); 
    Gift gift1 = Gift({
        claimable: false, 
        cost: 0, 
        additionalRequirements: false, 
        voucher: true 
        }); 
    Gift gift2 = Gift({
        claimable: false, 
        cost: 0, 
        additionalRequirements: false, 
        voucher: true 
        }); 
    Gift gift3 = Gift({
        claimable: false, 
        cost: 0, 
        additionalRequirements: false, 
        voucher: true 
        }); 

    Gift[] public gifts = [raffleGift, gift1, gift2, gift3];

    /**
     * @notice constructor function: initiating loyalty gift contract. 
     * 
     * @dev the LoyaltyGift constructor takes to params: uri and tokenised (array denoting which gifts are - tokenised - vouchers.)
     * £todo URI STILL NEEDS TO BE CHANGED! 
     */
    constructor()
        LoyaltyGift(
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmYwka9JjzUCtFiF2PkMhAyfnL8cJSwjPL1fiszR21xfV5/{id}",
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
     * @dev £todo This function should take calldata to make more diverse logics possible. 
     *  
     */
    function requirementsLoyaltyGiftMet(address loyaltyCard, uint256 loyaltyGiftId, uint256 loyaltyPoints)
        public
        override
        returns (bool success)
    {
        if (loyaltyGiftId != 0) revert ("Invalid token");
        if (loyaltyPoints < raffleGift.cost) revert ("Not enough points.");
        
        bool check = super.requirementsLoyaltyGiftMet(loyaltyCard, loyaltyGiftId, loyaltyPoints);
        return check;
    }

    /** 
     * @notice issues random voucher, overrides standard function in LoyaltyGift contract. 
     * 
     */
    function issueLoyaltyVoucher(address loyaltyCard, uint256 loyaltyGiftId)
    public 
    override 
    {   
        uint256[] memory balanceVouchers = balanceOfBatch(
            [msg.sender, msg.sender, msg.sender], 
            [1, 2, 3]
            );

        if (balanceVouchers[1] + balanceVouchers[2] + balanceVouchers[3] == 0) {
            revert LoyaltyGift__NoVouchersAvailable(address(this));
        }
        
        // @dev: selection of loyalty gift Id subject to availabilty vouchers. 
        uint256 newLoyaltyGiftId = pseudoRandomNumber(
            balanceVouchers[1], 
            balanceVouchers[2], 
            balanceVouchers[3]
            ); 

        safeTransferFrom(msg.sender, loyaltyCard, newLoyaltyGiftId, 1, "");
    }

    function pseudoRandomNumber(uint256 numberVouchers1, uint256 numberVouchers2, uint256 numberVouchers3) private view returns (uint256) {
        uint256 totalVouchers = numberVouchers1 + numberVouchers2 + numberVouchers3; 

        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(
                block.timestamp, 
                msg.sender, 
                blockhash(block.number)
                ))
            ) % totalVouchers; 

        // test how / if this works when one or more vouchers has not been minted.. 
        if (randomNumber < numberVouchers1) return 1;
        if (randomNumber >= numberVouchers1 && randomNumber < (numberVouchers1 + numberVouchers2)) return 2;  
        if (randomNumber >= (numberVouchers1 + numberVouchers2) ) return 3;  

    }
}
