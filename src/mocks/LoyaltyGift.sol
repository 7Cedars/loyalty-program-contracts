// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// NB: see ERC1155 contract from openZeppelin for good example of how to use natspecs.
// 

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {LoyaltyProgram} from "../LoyaltyProgram.sol";
import {ILoyaltyGift} from "../../src/interfaces/ILoyaltyGift.sol";

/**
 * @title LoyaltyGift 
 * @author
 * @notice Counter intutively, this ERC1155 contract can be set to NOT mint any tokens. This is because it is easier (and possibly safer) for Loyalty_Program_ 
 * contracts to interact with one type of contract, instead of two.  
 */
contract LoyaltyGift is ERC1155, ILoyaltyGift {
    
    // /* errors */
    error LoyaltyGift__TokenNotOwnedByCard(address loyaltyToken);
    error LoyaltyGift__NoTokensAvailable(address loyaltyToken);
    error LoyaltyGift__NotTokenised(address loyaltyToken, uint256 loyaltyGiftId); 
    error LoyaltyGift__IllegalRedeem(address mintedAt, address redeemedFrom);
    error LoyaltyGift__TransferDenied(address loyaltyToken);
 
    /* State variables */
    uint256[] private s_tokenised; // 0 == false, 1 == true.  
    
    /* Events */

    /* FUNCTIONS: */
    constructor(string memory loyaltyTokenUri, uint256[] memory tokenised) ERC1155(loyaltyTokenUri) {
        s_tokenised = tokenised; 
        emit LoyaltyGiftDeployed(msg.sender, s_tokenised); 
    }

    // receive() external virtual payable {}

    /**
     * @dev Here NFT specific requirements are inserted through super statements 
     * in implementations of LoyaltyGift contract. 
     *
     */
    function requirementsLoyaltyGiftMet(address /*loyaltyCard*/, uint256 /*loyaltyGiftId*/, uint256 /*loyaltyPoints*/) public virtual returns (bool success) {
        return true;
    }

    /**
     * @dev Note that anyone can call this function. 
     * When one token is minted, will emit a TransferSINGLE event. 
     */
    function mintLoyaltyVouchers(uint256[] memory loyaltyGiftIds, uint256[] memory numberOfTokens) public {
        // check if any of the loyaltyGiftIds is not tokenised.
        for (uint256 i; i < loyaltyGiftIds.length; i++) {
            if (s_tokenised[loyaltyGiftIds[i]] == 0) {
                revert LoyaltyGift__NotTokenised(address(this), loyaltyGiftIds[i]); 
            }
        }

        _mintBatch(msg.sender, loyaltyGiftIds, numberOfTokens, ""); // emits batchtransfer event
    }


    /**
     * @notice Note that this function does NOT include a check on requirements - this HAS TO BE implemented on the side of the loyalty program contract. 
     * @notice also does not check if address is TBA / loyaltyCard
     *
     */
    function issueLoyaltyGift(address loyaltyCard, uint256 loyaltyGiftId, uint256 loyaltyPoints) public returns (bool success) {
        if (s_tokenised[loyaltyGiftId] == 0) {
            return requirementsLoyaltyGiftMet(loyaltyCard, loyaltyGiftId, loyaltyPoints); 
        }

        if (balanceOf(msg.sender, loyaltyGiftId)  == 0) {
            revert LoyaltyGift__NoTokensAvailable(address(this));
        }

        safeTransferFrom(msg.sender, loyaltyCard, loyaltyGiftId, 1, "");
        return true; // Yep - reverts and then stops. Do I need this return? If not - take out. 
    }
   
    /**
     * @notice includes check if token was minted by loyalty program that is redeemed from. This means that Loyalty Tokens can be 
     * freely transferred by customers, but can only be redeemed at the program where they were originally minted (and claimed by a customer).    
     * 
     * @notice It does NOT include a check on requirements - this HAS TO BE implemented on the side of the loyalty program contract. 
     *  
     *
     */
    function reclaimLoyaltyVoucher(address loyaltyCard, uint256 loyaltyGiftId) public returns (bool success) {
        // check if this loyaltyGift actually has tokens.
        if (s_tokenised[loyaltyGiftId] == 0) {
            revert LoyaltyGift__NotTokenised(address(this), loyaltyGiftId); 
        }

        _safeTransferFrom(loyaltyCard, msg.sender, loyaltyGiftId, 1, "");
        return true; // TEST if this does not come through when _safeTransferFrom reverts. 
    }


    // = Implemented. 
    // As it is now, loyaltyTokens minted in one program, CAN BE EXCHANGED in ANOTHER PROGRAM! 
    // I HAVE TO change this. ALL tokens should just stay on card. No transfers allowed. 
    // only transfer allowed is from loyaltyProgram -> loyaltyCard. 
    // (Note that loyaltyCards CAN be transferred, so people can still swap. )
    /* internal */
    /**
     * @dev When a LoyaltyPrograms transfer tokens (= gift them) they need to pass requirementsLoyaltyGiftMet. 
     * In any other case, tokens ought to be freely transferable.    
     * @dev All other params remain unchanged.
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override
    {
        // Checks if 1: msg.sender == LoyaltyProgram 2: to == LoyaltyCard at Loyalty Program and 3: if LoyaltyCard has Balance. 
        // DOES NOT QUITE WORK YET... 
        // if (LoyaltyProgram(payable(msg.sender)).balanceOf(to, 0) == 0) { 
        //     revert LoyaltyGift__TransferDenied(address(this));
        //     }
        super._update(from, to, ids, values);
    }

    /* getter functions */
    function getTokenised() external view returns (uint256[] memory) {
        return s_tokenised; 
    }
}
