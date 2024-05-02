// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @dev the ERC-165 identifier for this interface is ... 
interface ILoyaltyProgram is IERC165, IERC1155 {

  function mintLoyaltyCards(uint256 numberOfLoyaltyCards) external; 

  function mintLoyaltyPoints(uint256 numberOfPoints) external;

  function addLoyaltyGift(address loyaltyGiftAddress, uint256 loyaltyGiftId) external;

  function removeLoyaltyGiftClaimable(address loyaltyGiftAddress, uint256 loyaltyGiftId) external; 
   
  function removeLoyaltyGiftRedeemable(address loyaltyGiftAddress, uint256 loyaltyGiftId) external;

  function checkRequirementsLoyaltyGiftMet(address loyaltyCard, address loyaltyGiftAddress, uint256 loyaltyGiftId) external returns (bool);

  function mintLoyaltyVouchers(address loyaltyGiftAddress, uint256[] memory loyaltyGiftIds, uint256[] memory numberOfVouchers) external; 

  function transferLoyaltyVoucher(address from, address to, address loyaltyGiftAddress, uint256 loyaltyGiftId) external; 

  function claimLoyaltyGift(
        string memory _gift,
        string memory _cost,
        address loyaltyGiftAddress,
        uint256 loyaltyGiftId,
        uint256 loyaltyCardId,
        address customerAddress,
        uint256 loyaltyPoints,
        bytes memory signature
    ) external; 

  function redeemLoyaltyVoucher(
        string memory _voucher,
        address loyaltyGiftAddress,
        uint256 loyaltyGiftId,
        uint256 loyaltyCardId,
        address customerAddress,
        bytes memory signature
    ) external;

  function getOwner() external view returns (address);

  function getTokenBoundAddress(uint256 _loyaltyCardId) external view returns (address);

  function getLoyaltyGiftIsClaimable(address loyaltyGiftAddress, uint256 loyaltyGiftId) external view returns (uint256);

  function getLoyaltyGiftIsRedeemable(address loyaltyGiftAddress, uint256 loyaltyGiftId) external view returns (uint256);

  function getNumberLoyaltyCardsMinted() external view returns (uint256);

  function getBalanceLoyaltyCard(address loyaltyCardAddress) external view returns (uint256);

  function getNonceLoyaltyCard(address loyaltyCardAddress) external view returns (uint256);
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


