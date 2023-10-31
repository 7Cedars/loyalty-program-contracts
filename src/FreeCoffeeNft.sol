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

pragma solidity ^0.8.21;

import {LoyaltyNft} from "./LoyaltyNft.sol";

contract FreeCoffeeNft is LoyaltyNft {

  constructor() LoyaltyNft(
    2500, 
    "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7") {
    }
}