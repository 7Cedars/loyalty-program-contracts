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

import {LoyaltyNft} from "./LoyaltyNft.sol";
import {Transaction} from "./LoyaltyProgram.sol";

///////////////////////////////////////////////
///                 EXAMPLE 1               ///
///////////////////////////////////////////////
/** 
 * @dev This example LoyaltyNft contract gives a free coffee for 2500 loyalty points. 
*/ 
contract FreeCoffeeNft is LoyaltyNft {

  /** 
   * @dev the constructor defines the uri of the LoyaltyNft contract.    
   * This example gives out a free coffee NFT for 2500 loyalty points. 
   * first value in constructor is the s_loyaltyNftPrice (2500) 
   * second value in constructor is the NFT Metadata CID. (pointing to image and description of NFT / redeem value)
  */ 
  constructor() LoyaltyNft(
    "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7") {
  }

  /** 
   * @dev This is the actual claim logic / price of the NFT. 
   * It is coded in the form of if-revert statements. 
   * See the base LoyaltyNft contract for available error statements. // TODO: need to add more. 
   * In this case it is a simple 'if not enough points -> revert' logic. 
  */ 
  function requirementsNftMet(
    address consumer, 
    uint256 loyaltyPoints, 
    Transaction[] memory transactions
    ) public override returns (bool success) {
      uint256 nftPointsPrice = 2500; 
      
      if (loyaltyPoints < nftPointsPrice) {
        revert LoyaltyNft__InsufficientPoints(); 
      }

      super.requirementsNftMet(consumer, loyaltyPoints, transactions); 
    }
}

///////////////////////////////////////////////
///                 EXAMPLE 2               ///
///////////////////////////////////////////////
/** 
 * @dev This example LoyaltyNft contract gives a free coffee for 2500 loyalty points. 
*/ 
contract FreeCoffeeForSprinters is LoyaltyNft {

  /** 
   * @dev This example gives out a free coffee if a customer has made at least 10 purchases in a week. 
   * note that is assumes that transactions are given chronologically!  
   * The NFT Metadata CID. (pointing to image and description of NFT / redeem value)
  */ 
  constructor() LoyaltyNft(
    "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7") { // has to still change
  }

  /** 
   * @dev This is the actual claim logic / price of the NFT. 
   * It is coded in the form of if-revert statements. 
   * See the base LoyaltyNft contract for available error statements. // TODO: need to add more. 
   * In this case a customer needs 10 transactions within one week to claim the NFT. 
  */ 
  function requirementsNftMet(
    address consumer, 
    uint256 loyaltyPoints, 
    Transaction[] memory transactions
    ) public override returns (bool success) {
      uint256 oneWeek = 604800; // one week in seconds.
      uint256 numberOfTransactions = transactions.length; 
      uint256 durationOfTransactions = transactions[numberOfTransactions - 1].timestamp - transactions[0].timestamp; 
      
      if (durationOfTransactions < oneWeek || numberOfTransactions < 10) {
        revert LoyaltyNft__InsufficientTransactions(); 
      }

    super.requirementsNftMet(consumer, loyaltyPoints, transactions); 
  }
}

///////////////////////////////////////////////
///                 EXAMPLE 3               ///
///////////////////////////////////////////////
/** 
 * @dev This example LoyaltyNft contract is a combination of Example 1 and 2: combining transactions with points.   
*/ 
contract FreeCoffeeForRichSprinters is LoyaltyNft {

  /** 
   * @dev This example gives out a free coffee if a customer has made at least 10 purchases in a week + transfers 2500 points. 
   * note that is assumes that transactions are given chronologically!
   * The NFT Metadata CID. (pointing to image and description of NFT / redeem value)
  */ 
  constructor() LoyaltyNft(
    "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7") { // has to still change
  }

  /** 
   * @dev This is the actual claim logic / price of the NFT. 
   * It is coded in the form of if-revert statements. 
   * See the base LoyaltyNft contract for available error statements. // TODO: need to add more. 
   * In this case a customer needs 10 transactions within one week to claim the NFT. 
  */ 
  function requirementsNftMet(
    address consumer, 
    uint256 loyaltyPoints, 
    Transaction[] memory transactions
    ) public override returns (bool success) {
      uint256 nftPointsPrice = 2500; 
      uint256 oneWeek = 604800; // one week in seconds.
      uint256 numberOfTransactions = transactions.length; 
      uint256 durationOfTransactions = transactions[numberOfTransactions - 1].timestamp - transactions[0].timestamp; 
      
      if (durationOfTransactions < oneWeek || numberOfTransactions < 10 || loyaltyPoints < nftPointsPrice) {
        revert LoyaltyNft__InsufficientTransactionsAndPoints();
      }

    super.requirementsNftMet(consumer, loyaltyPoints, transactions); 
  }
}