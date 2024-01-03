// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @dev the ERC-165 identifier for this interface is `0xeff4d378`
interface ILoyaltyToken is IERC1155 {

      /* errors */
    error LoyaltyToken__LoyaltyProgramNotRecognised(address loyaltyToken);
    error LoyaltyToken__NftNotOwnedByloyaltyCard(address loyaltyToken);
    error LoyaltyToken__InsufficientPoints(address loyaltyToken);

    /**
     * @dev natspecs TBI 
     */
    event DiscoverableLoyaltyToken(address indexed issuer);

    // receive() external payable;

    /**
     * @dev natspecs TBI 
     */
    function makeDiscoverable() external; 

    /**
     * @dev natspecs TBI 
     */
    function mintLoyaltyTokens(uint256 numberOfTokens) external; 

    /**
     * @dev natspecs TBI 
     */
    function requirementsLoyaltyTokenMet(address /* loyaltyCard */, uint256  /* loyaltypoints */) external returns (bool success);

    /**
     * @dev natspecs TBI 
     */
    function claimLoyaltyToken(address loyaltyCard) external returns (uint256 tokenId);

    /**
     * @dev natspecs TBI 
     */
    function getAvailableTokens(address loyaltyCard) external view returns (uint256);
}