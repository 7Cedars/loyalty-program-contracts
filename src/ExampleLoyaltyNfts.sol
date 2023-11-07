// SPDX-License-Identifier: MIT

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

// NB: still need to edit these contracts and update descriptions... 
pragma solidity ^0.8.21;

import {LoyaltyToken} from "./LoyaltyToken.sol";

///////////////////////////////////////////////
///                 EXAMPLE 1               ///
///////////////////////////////////////////////
/** 
 * @dev This example LoyaltyNft contract gives a free coffee for 2500 loyalty points. 
*/ 
contract OneCoffeeFor2500 is LoyaltyToken {

  /** 
   * @dev the constructor defines the uri of the LoyaltyNft contract.    
   * This example gives out a free coffee NFT for 2500 loyalty points. 
   * first value in constructor is the s_loyaltyNftPrice (2500) 
   * second value in constructor is the NFT Metadata CID. (pointing to image and description of NFT / redeem value)
  */ 
  constructor() LoyaltyToken(
    "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7") {
  }

  /** 
   * @dev This is the actual claim logic / price of the NFT. 
   * It is coded in the form of if-revert statements. 
   * See the base LoyaltyNft contract for available error statements. // TODO: need to add more. 
   * In this case it is a simple 'if not enough points -> revert' logic. 
  */ 
  function requirementsLoyaltyTokenMet(
    address loyaltyCard, 
    uint256 loyaltyPoints
    ) public override returns (bool success) {
      uint256 nftPointsPrice = 2500; 
      
      if (loyaltyPoints < nftPointsPrice) {
        revert LoyaltyToken__InsufficientPoints(address(this)); 
      }

    super.requirementsLoyaltyTokenMet(loyaltyCard, loyaltyPoints); 
    }
}