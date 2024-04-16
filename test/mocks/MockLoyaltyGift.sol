// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol"; // ERC165 not implemented for now. 
// import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol"; // ERC165 not implemented for now. 
import {ERC1155} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {IERC1155} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
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
contract MockLoyaltyGift is ERC1155, ILoyaltyGift {
    /* errors */
    error LoyaltyGift__NoVouchersAvailable(address loyaltyToken);
    error LoyaltyGift__IsNotVoucher(address loyaltyToken, uint256 loyaltyGiftId);
    error LoyaltyGift__TransferDenied(address loyaltyToken);
    error LoyaltyGift__MissingAddressLoyaltyProgram(address loyaltyToken); 

    /* State variables */
    uint256[] s_isClaimable; 
    uint256[] s_isVoucher; 
    uint256[] s_cost;
    uint256[] s_hasAdditionalRequirements;   

    /* FUNCTIONS: */
    /**
     * @notice constructor function. 
     * 
     * @param loyaltyTokenUri URI of vouchers. Follows ERC 1155 standard.  
     * @param isClaimable => can gift directly be claimed by customer?
     * @param isVoucher => is the gift a voucher (to be redeemed later) or has to be immediatly redeemed at the till? 
     * @param cost =>  What is cost (in points) of voucher? 
     * @param hasAdditionalRequirements =>  Are their additional requirements? 
     * 
     * emits a LoyaltyGiftDeployed event.  
     */
    constructor(
        string memory loyaltyTokenUri, 
        uint256[] memory isClaimable,
        uint256[] memory isVoucher,
        uint256[] memory cost,
        uint256[] memory hasAdditionalRequirements   
        ) ERC1155(loyaltyTokenUri) {
            s_isClaimable = isClaimable; 
            s_isVoucher = isVoucher;
            s_cost = cost;
            s_hasAdditionalRequirements = hasAdditionalRequirements;  
            
            emit LoyaltyGiftDeployed(msg.sender);
    }

    function test() public { } // skip in foundry coverage  

    /**
     * @notice provides the requirement logics for receiving gifts.  Returns true or false. 
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
    function requirementsLoyaltyGiftMet(address, /*loyaltyCard*/ uint256 loyaltyGiftId, uint256 /*loyaltyPoints*/ )
        public
        virtual
        returns (bool success)
    {
        if (s_isClaimable[loyaltyGiftId] == 0) revert ("Token is not claimable."); 

        return true;
    }

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
    function mintLoyaltyVouchers(uint256[] memory loyaltyGiftIds, uint256[] memory numberOfVouchers) public {
        
        for (uint256 i; i < 1; ) { // uint256 i; i < loyaltyGiftIds.length; 
            if (s_isVoucher[loyaltyGiftIds[i]] == 0) {
                revert LoyaltyGift__IsNotVoucher(address(this), loyaltyGiftIds[i]);
            }
        unchecked { i++; } 
        }
        _mintBatch(LoyaltyProgram(msg.sender).getOwner(), loyaltyGiftIds, numberOfVouchers, ""); // emits batchtransfer event
    }


    /**
     * @notice added checks to safeTransfer that ensure vouchers can only be transferred between Loyalty Cards and their Loyalty Program. 
     * 
     * @param from address from which voucher is send. 
     * @param to address at which voucher is received. 
     * @param id array of voucher ids sent. 
     * @param amount array of amount of vouchers sent per id.
     * 
     * @dev ids and values need to be array of same length.  
     * @dev The check is ignored when vouchers are minted. It means any address can mint vouchers. But if they lack TBAs, addresses cannot do anything with these vouchers. 
     * @dev I here update safeTransferFrom (and not the inetrnal _update function) because _update does not take a data field.  
     * 
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public
        override(ERC1155, IERC1155)
    {
        
        // check if transfer is going or coming from Loyalty Card registered with Loyalty Program.   
        if (address(0) != from) {
            // @dev these two if statements combine to check: 
            // to or from == program owner? if not, addresses HAVE to be from loyalty card. 
            // it excludes any addresses not affiliated with loyalty program. 
            // hence we can bypass additional check of safeTransferFrom. 

            if (LoyaltyProgram(msg.sender).getOwner() != to) {
                try LoyaltyProgram(msg.sender).getBalanceLoyaltyCard(to) {}
                catch { revert LoyaltyGift__TransferDenied(address(this)); }
            }
            if (LoyaltyProgram(msg.sender).getOwner() != from) {
                try LoyaltyProgram(msg.sender).getBalanceLoyaltyCard(from) {}
                catch { revert LoyaltyGift__TransferDenied(address(this)); }
            }
        } 
        super._safeTransferFrom(from, to, id, amount, data);
    }

    /* getter functions */
    function getNumberOfGifts() external view returns (uint256) {
        return s_isClaimable.length;
    }

    function getIsClaimable(uint256 index) external view returns (uint256) {
        return s_isClaimable[index];
    } 

    function getIsVoucher(uint256 index) external view returns (uint256) {
        return s_isVoucher[index]; 
    }

    function getCost(uint256 index) external view returns (uint256) {
        return s_cost[index];
    }

    function getHasAdditionalRequirements(uint256 index) external view returns (uint256) {
        return s_hasAdditionalRequirements[index]; 
    }
}
