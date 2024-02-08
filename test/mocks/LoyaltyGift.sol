// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol"; // ERC165 not implemented for now. 
// import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol"; // ERC165 not implemented for now. 
import {ERC1155} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {LoyaltyProgram} from "../../src/LoyaltyProgram.sol";
import {ILoyaltyGift} from "../../src/interfaces/ILoyaltyGift.sol";

/**
 * @title Loyalty Gift
 * @author Seven Cedars, based on ERC-1155 implementation by OpenZeppelin.
 * 
 * @notice An ERC-1155 based standard contract that provides requirements for providing gifts; and (optionally) mints tokens that enable delayed exchange of gifts through vouchers. 
 * @dev This contract provides a standard implementation (of the ILoyaltyGift interface) that can be inhereted by actual gift contracts.  
 *   
 * @dev Counter intutively, this ERC1155 contract can be set to NOT mint any vouchers. This is because it is easier (and possibly safer) for Loyalty_Program_
 * contracts to interact with one type of contract, instead of two.
 */
contract LoyaltyGift is ERC1155, ILoyaltyGift {
    // /* errors */
    error LoyaltyGift__NoTokensAvailable(address loyaltyToken);
    error LoyaltyGift__NotTokenised(address loyaltyToken, uint256 loyaltyGiftId);
    error LoyaltyGift__TransferDenied(address loyaltyToken);

    /* State variables */
    uint256[] private s_tokenised; // 0 == false, 1 == true.


    /* FUNCTIONS: */
    /**
     * @notice constructor function. 
     * 
     * @param loyaltyTokenUri URI of vouchers. Follows ERC 1155 standard.  
     * @param tokenised array of 0 and 1's to indicate what gifts have vouchers (= token) and which ones do not. 
     * 
     * emits a LoyaltyGiftDeployed event.  
     */
    constructor(string memory loyaltyTokenUri, uint256[] memory tokenised) ERC1155(loyaltyTokenUri) {
        s_tokenised = tokenised;
        emit LoyaltyGiftDeployed(msg.sender, s_tokenised);
    }

    /**
     * @notice The cdntral function providing the requirement logics for receiving gifts.  Returns true or false. 
     * 
     * @dev In this standard implementation this function always returns true. 
     * @dev specific loyalty gift implementations should override this function.
     *
     * optional inputs are
     * - loyaltyCard: LoyaltyCard address
     * - loyaltyGiftId: LoyaltyGift Id 
     * - loyaltyPoints: number of LoyaltyPoints sent. 
     *
     */
    function requirementsLoyaltyGiftMet(address, /*loyaltyCard*/ uint256, /*loyaltyGiftId*/ uint256 /*loyaltyPoints*/ )
        public
        virtual
        returns (bool success)
    {
        return true;
    }

    /**
     * @notice mints loyalty vouchers by external EOA or smart contract address. 
     * 
     * @dev Note that anyone can call this function.
     * @dev It checks if gift is tokenised. Reverts if not. 
     * 
     * emits a TransferSINGLE event when one type of voucher minted; TransferBatch when multiple are minted. 
     * £todo: CHECK If this is true!  
     */
    function mintLoyaltyVouchers(uint256[] memory loyaltyGiftIds, uint256[] memory numberOfTokens) public {
        for (uint256 i; i < loyaltyGiftIds.length; ) {
            if (s_tokenised[loyaltyGiftIds[i]] == 0) {
                revert LoyaltyGift__NotTokenised(address(this), loyaltyGiftIds[i]);
            }
        unchecked { ++i; } 
        }
        _mintBatch(msg.sender, loyaltyGiftIds, numberOfTokens, ""); // emits batchtransfer event
    }

    /**
     * 
     * CONTINUE HERE WITH NATSPECCING 
     * 
     */

    /**
     * @notice transfers loyalty voucher and . 
     * 
     * @param loyaltyCard text
     * @param loyaltyGiftId text
     * 
     * @dev Note that this function does NOT include a check on requirements - this HAS TO BE implemented on the side of the loyalty program contract.
     * @dev also does not check if address is TBA / loyaltyCard
     *
     */
    function issueLoyaltyVoucher(address loyaltyCard, uint256 loyaltyGiftId)
        public
    {
        if (s_tokenised[loyaltyGiftId] == 0) {
            revert LoyaltyGift__NotTokenised(address(this), loyaltyGiftId);
        }

        if (balanceOf(msg.sender, loyaltyGiftId) == 0) {
            revert LoyaltyGift__NoTokensAvailable(address(this));
        }

        safeTransferFrom(msg.sender, loyaltyCard, loyaltyGiftId, 1, "");
    }

    /**
     * @dev includes check if token was minted by loyalty program that is redeemed from. This means that Loyalty Tokens can be
     * freely transferred by customers, but can only be redeemed at the program where they were originally minted (and claimed by a customer).
     *
     * @dev It does NOT include a check on requirements - this HAS TO BE implemented on the side of the loyalty program contract.
     *
     *
     */
    function redeemLoyaltyVoucher(address loyaltyCard, uint256 loyaltyGiftId) public returns (bool success) {
        // check if this loyaltyGift actually has tokens.
        if (s_tokenised[loyaltyGiftId] == 0) {
            revert LoyaltyGift__NotTokenised(address(this), loyaltyGiftId);
        }

        _safeTransferFrom(loyaltyCard, msg.sender, loyaltyGiftId, 1, "");
        return true; // TEST if this does not come through when _safeTransferFrom reverts.
    }

    /* internal */
    /**
     * @notice added checks to safeTransfer that tokens can only be transferred between Loyalty Cards and its Loyalty Program. 
     *  
     * @dev Vouchers cannot be claimed or redeemed when balance of loyaltypoints on card == 0.  
     * @dev The check is ignored when vouchers are minted. 
     * @dev £todo? if the card does not exist at the program; the transfer gets an EVM revert. It's not pretty. Maybe should use try - catch structure. 
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override
    {
        if (address(0) != from) {
            if (msg.sender == from) {
                if (LoyaltyProgram(msg.sender).getBalanceLoyaltyCard(to) == 0)
                {  revert LoyaltyGift__TransferDenied(address(this)); }
            }
            if (msg.sender == to) {
                if (LoyaltyProgram(msg.sender).getBalanceLoyaltyCard(from) == 0) 
                {  revert LoyaltyGift__TransferDenied(address(this)); }
            }
        } 
        super._update(from, to, ids, values);
    }

    /* getter functions */
    function getTokenised() external view returns (uint256[] memory) {
        return s_tokenised;
    }
}
