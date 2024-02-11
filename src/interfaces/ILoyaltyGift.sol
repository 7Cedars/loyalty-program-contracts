// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @dev the ERC-165 identifier for this interface is `0xeff4d378`
interface ILoyaltyGift is IERC1155 {
    /* errors */
    error LoyaltyGift__LoyaltyProgramNotRecognised(address loyaltyToken);
    error LoyaltyGift__NftNotOwnedByloyaltyCard(address loyaltyToken);
    error LoyaltyGift__RequirementsNotMet(address loyaltyToken, uint256 loyaltyGiftId);

    /**
     * @dev natspecs TBI
     */
    event LoyaltyGiftDeployed(address indexed issuer, uint256[] tokenised);

    /**
     * @notice provides the requirement logics for receiving gifts.  Returns true or false. 
     * 
     * @dev In this standard implementation this function always returns true. 
     * @dev specific loyalty gift implementations should override this function.
     *
     * optional inputs are
     * @param loyaltyCard: LoyaltyCard address
     * @param loyaltyGiftId: LoyaltyGift Id 
     * @param loyaltyPoints: number of LoyaltyPoints sent. 
     *
     */
    function requirementsLoyaltyGiftMet(address loyaltyCard, uint256 loyaltyGiftId, uint256 loyaltyPoints)
        external
        returns (bool success);


    /**
     * @notice mints loyalty vouchers by external EOA or smart contract address. 
     * 
     * @param loyaltyGiftIds array: ids of vouchers to mint 
     * @param numberOfVouchers array: number of vouchers to mint for each id.  
     * 
     * @dev loyaltyGiftIds and numberOfVouchers need to be arrays of the same length.  
     * @dev Note that anyone can call this function.
     * @dev It checks if gift is tokenised. Reverts if not. 
     * 
     * emits a TransferSINGLE event when one type of voucher minted; TransferBatch when multiple are minted. 
     * £todo: CHECK If this is true!  
     */
    function mintLoyaltyVouchers(uint256[] memory loyaltyGiftIds, uint256[] memory numberOfVouchers) external;

    /**
     * @notice transfers loyalty voucher from loyalty Program to a loyaltyCard. 
     * 
     * @param loyaltyCard the address of the loyalty Card. 
     * @param loyaltyGiftId the id of the voucher to be transferred. 
     * 
     * @dev Note that this function does NOT include a check on requirements - this HAS TO BE implemented on the side of the loyalty program contract.
     * @dev same goes for payment in loyalty Points - not included here. 
     * @dev also does not check if address is TBA / loyaltyCard -- done at safeTransferFrom. 
     *
     */
    function issueLoyaltyVoucher(address loyaltyCard, uint256 loyaltyGiftId) external; 

    /**
     * @notice transfers loyalty voucher from a loyaltyCard to a LoyaltyProgram. 
     * 
     * @param loyaltyCard the address of the loyalty Card. 
     * @param loyaltyGiftId the id of the voucher to be transferred. 
     * 
     * @dev adds check if gift is actually tokenised.
     * @dev It does NOT include a check on requirements - this HAS TO BE implemented on the side of the loyalty program contract.
     * @dev also does not check if address is TBA / loyaltyCard -- see safeTransferFrom for this. 
     */
    function redeemLoyaltyVoucher(address loyaltyCard, uint256 loyaltyGiftId) external;
}

// Structure contract // -- from Patrick Collins. 
/* version */
/* imports */
/* errors */
/* interfaces, libraries, contracts */
/* Type declarations */
/* State variables */
/* Events */
/* Modifiers */

/* FUNCTIONS: */
/* constructor */
/* receive function (if exists) */
/* fallback function (if exists) */
/* external */
/* public */
/* internal */
/* private */
/* internal & private view & pure functions */
/* external & public view & pure functions */
