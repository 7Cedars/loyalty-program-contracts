// SPDX-License-Identifier: MIT
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
     * @dev
     */
    constructor() LoyaltyToken("ipfs://QmPJk5U1nb7Hn94DXmCbMWPrV8tmqY4jTdUakFVeHCSZPN") {}

    /**
     * @dev This is the actual claim logic / price of the NFT.
     * Now simple, but can include any kind of additional data (from, for instance, chainlink).
     */
    function requirementsLoyaltyTokenMet(address loyaltyCard, uint256 loyaltyPoints)
        public
        override
        returns (bool success)
    {
        uint256 nftPointsPrice = 2500; // this should be global constant. Or even in the constructor.

        if (loyaltyPoints < nftPointsPrice) {
            revert LoyaltyToken__InsufficientPoints(address(this));
        }

        super.requirementsLoyaltyTokenMet(loyaltyCard, loyaltyPoints);
    }
}

///////////////////////////////////////////////
///                 EXAMPLE 2               ///
///////////////////////////////////////////////
/**
 * @dev This example LoyaltyNft contract gives a free coffee for 2500 loyalty points.
 */
contract OneCupCakeFor4500 is LoyaltyToken {
    /**
     * @dev
     */
    constructor() LoyaltyToken("ipfs://Qme1cD6rU7DzgkMEaveWegXLawz33epPJBY8YkwLPrciX9") {}

    /**
     * @dev This is the actual claim logic / price of the NFT.
     * Now simple, but can include any kind of additional data (from, for instance, chainlink).
     */
    function requirementsLoyaltyTokenMet(address loyaltyCard, uint256 loyaltyPoints)
        public
        override
        returns (bool success)
    {
        uint256 nftPointsPrice = 4500; 

        if (loyaltyPoints < nftPointsPrice) {
            revert LoyaltyToken__InsufficientPoints(address(this));
        }

        super.requirementsLoyaltyTokenMet(loyaltyCard, loyaltyPoints);
    }
}

///////////////////////////////////////////////
///                 EXAMPLE 3               ///
///////////////////////////////////////////////
/**
 * @dev This example LoyaltyNft contract gives a free coffee for 2500 loyalty points.
 */
contract AccessPartyFor50000 is LoyaltyToken {
    /**
     * @dev
     */
    constructor() LoyaltyToken("ipfs://QmXHmtJLvxKSt63Ht8mTmHnGoqNQ3GzZ3cxE43eQHXtY5X") {}

    /**
     * @dev This is the actual claim logic / price of the NFT.
     * Now simple, but can include any kind of additional data (from, for instance, chainlink).
     */
    function requirementsLoyaltyTokenMet(address loyaltyCard, uint256 loyaltyPoints)
        public
        override
        returns (bool success)
    {
        uint256 nftPointsPrice = 50000; 

        if (loyaltyPoints < nftPointsPrice) {
            revert LoyaltyToken__InsufficientPoints(address(this));
        }

        super.requirementsLoyaltyTokenMet(loyaltyCard, loyaltyPoints);
    }
}