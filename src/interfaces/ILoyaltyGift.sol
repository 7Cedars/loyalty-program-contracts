// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @dev the ERC-165 identifier for this interface is `0xeff4d378`
interface ILoyaltyGift is IERC1155 {
    /* errors */
    error LoyaltyGift__LoyaltyProgramNotRecognised(address loyaltyToken);
    error LoyaltyGift__NftNotOwnedByloyaltyCard(address loyaltyToken);
    error LoyaltyGift__RequirementsNotMet(address loyaltyToken, uint256 loyaltyTokenId);

    /**
     * @dev natspecs TBI
     */
    event LoyaltyGiftDeployed(address indexed issuer, uint256[] tokenised);

    // receive() external payable;
    /**
     * @dev natspecs TBI
     */
    function requirementsLoyaltyGiftMet(address loyaltyCard, uint256 loyaltyTokenId, uint256 loyaltyPoints)
        external
        returns (bool success);

    /**
     * @dev natspecs TBI
     */
    function mintLoyaltyVouchers(uint256[] memory loyaltyGiftIds, uint256[] memory numberOfTokens) external;

    /**
     * @dev natspecs TBI
     */
    function issueLoyaltyGift(address loyaltyCard, uint256 loyaltyTokenId, uint256 loyaltyPoints)
        external
        returns (bool success);

    /**
     * @dev natspecs TBI
     */
    function reclaimLoyaltyVoucher(address loyaltyCard, uint256 tokenId) external returns (bool success);
}
