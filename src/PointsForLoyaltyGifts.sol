// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {LoyaltyGift} from "./LoyaltyGift.sol";
import {ILoyaltyGift} from "../src/interfaces/ILoyaltyGift.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {LoyaltyProgram} from "./LoyaltyProgram.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

///////////////////////////////////////////////
///                 EXAMPLE 1               ///
///////////////////////////////////////////////
/**
 * @dev This example LoyaltyNft contract gives a free coffee for 2500 loyalty points.
 */
contract OneCoffeeFor2500 is LoyaltyGift {
    /**
     * @dev
     */
    constructor() LoyaltyGift("https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmX5em6Dh4XgnZ6pe4igkZqkf6mSRTRbNja2w3qE8qcfGT", true) { }

    // receive() external override payable { 
    //     return(); 
    // } 
    
    /**
     * @dev This is the actual claim logic / price of the NFT.
     * Now simple, but can include any kind of additional data (from, for instance, chainlink).
     */
    function requirementsLoyaltyGiftMet(address loyaltyCard, uint256 loyaltyPoints) public override returns (bool success) {
        uint256 nftPointsPrice = 2500; // this should be global constant. Or even in the constructor.
        if (loyaltyPoints < nftPointsPrice) {
            revert LoyaltyGift__InsufficientPoints(address(this));
        }

        bool check = super.requirementsLoyaltyGiftMet(loyaltyCard, loyaltyPoints);
        return check; 
    }
}

// ///////////////////////////////////////////////
// ///                 EXAMPLE 2               ///
// ///////////////////////////////////////////////
/**
 * @dev This example LoyaltyNft contract gives a free coffee for 2500 loyalty points.
 */
contract OneCupCakeFor4500 is LoyaltyGift {
    /**
     * @dev
     */
    constructor() LoyaltyGift("https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmWA2RjPJ8mzer6AWM9XY5XCSRhSfWTm3yLwK2YVE8D4pH", true) { }

    // receive() external override payable { 
    //     return(); 
    // } 

    /**
     * @dev This is the actual claim logic / price of the NFT.
     * Now simple, but can include any kind of additional data (from, for instance, chainlink).
     */
    function requirementsLoyaltyGiftMet(address loyaltyCard, uint256 loyaltyPoints) public override returns (bool success) {
        uint256 nftPointsPrice = 4500; 

        if (loyaltyPoints < nftPointsPrice) {
            revert LoyaltyGift__InsufficientPoints(address(this));
        }
        bool check = super.requirementsLoyaltyGiftMet(loyaltyCard, loyaltyPoints);
        return check; 
    }
}

///////////////////////////////////////////////
///                 EXAMPLE 3               ///
///////////////////////////////////////////////
/**
 * @dev This example LoyaltyNft contract gives a free coffee for 2500 loyalty points.
 */
contract AccessPartyFor50000 is LoyaltyGift {
    /**
     * @dev
     */
    constructor() LoyaltyGift("https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmarurBe5SNSJ94qskJz7Eb95doFTTFb8wQqvBvEJtBerP", true) {}

    // receive() external override payable { 
    //     return( ); 
    // } 

    /**
     * @dev This is the actual claim logic / price of the NFT.
     * Now simple, but can include any kind of additional data (from, for instance, chainlink).
     */
    function requirementsLoyaltyGiftMet(address loyaltyCard, uint256 loyaltyPoints ) public override returns (bool success) {
        uint256 nftPointsPrice = 50000; 

        if (loyaltyPoints < nftPointsPrice) {
            revert LoyaltyGift__InsufficientPoints(address(this));
        }

        bool check = super.requirementsLoyaltyGiftMet(loyaltyCard, loyaltyPoints);
        return check; 
    }
}