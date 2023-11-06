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

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Transaction} from "./LoyaltyProgram.sol";

contract LoyaltyToken is ERC1155 {

  /* errors */ 
  error LoyaltyToken__LoyaltyProgramNotRecognised(address loyaltyToken);
  error LoyaltyToken__NftNotOwnedByloyaltyCard(address loyaltyToken); 
  error LoyaltyToken__NoTokensAvailable(address loyaltyToken); 
  error LoyaltyToken__InsufficientPoints(address loyaltyToken); 
  error LoyaltyToken__InsufficientTransactions(address loyaltyToken); 
  error LoyaltyToken__InsufficientTransactionsAndPoints(address loyaltyToken); 

  /* State variables */ 
  mapping (uint256 => address) private s_tokenIdToLoyaltyProgram; 
  mapping (address => uint256[]) private s_loyaltyProgramToTokenIds; 
  uint256 private s_tokenCounter;

  /* Events */

  /* FUNCTIONS: */
  constructor(string memory loyaltyTokenUri) ERC1155("") {
    s_tokenCounter = 0;
    _setURI(loyaltyTokenUri); 
  }

  function mintLoyaltyTokens(uint256 numberOfTokens) public {
    uint256[] memory loyaltyTokenIds = new uint256[](numberOfTokens); 
    uint256[] memory mintNfts = new uint256[](numberOfTokens); 
    uint256 counter = s_tokenCounter; 

    for (uint i; i < numberOfTokens; i++) { // i starts at 0.... right? TEST! 
      counter = counter + 1; 
      loyaltyTokenIds[i] = counter;
      mintNfts[i] = 1;
      s_tokenIdToLoyaltyProgram[i] = msg.sender; 
    }
    _mintBatch(msg.sender, loyaltyTokenIds, mintNfts, ""); // emits batchtransfer event
    
    s_tokenCounter = s_tokenCounter + numberOfTokens; 
    s_loyaltyProgramToTokenIds[msg.sender] = loyaltyTokenIds; 
  }

  /** 
   * @dev TODO
   * 
   * 
  */ 
  function redeemNft(address loyaltyCard, uint256 tokenId) public {
    if (balanceOf(loyaltyCard, tokenId) == 0) {
      revert LoyaltyToken__NftNotOwnedByloyaltyCard(address(this)); 
    }
    if (s_tokenIdToLoyaltyProgram[tokenId] != msg.sender) {
      revert LoyaltyToken__LoyaltyProgramNotRecognised(address(this)); 
    }

    _safeTransferFrom(loyaltyCard, address(0), tokenId, 1, ""); // emits singleTransfer event. 
  }

  // CONTINUE HERE 
  /** 
   * @dev TODO 
   * 
   * 
  */ 
  function requirementsLoyaltyTokenMet(
    address, 
    uint256, 
    Transaction[] memory
    ) public virtual returns (bool success) {
      
      // Here NFT specific requirements are inserted. 

      return true; 
  }
  
  /** 
   * @dev NB: This won't work. Need another logic due to 1155 logic.  
   * 
   * 
  */ 
  function claimNft(address loyaltyCard) public {
    uint256 maxIndex = s_loyaltyProgramToTokenIds[msg.sender].length;
    if (maxIndex == 0) {
      revert LoyaltyToken__NoTokensAvailable(address(this)); 
    }
    
    uint tokenId = s_loyaltyProgramToTokenIds[msg.sender][maxIndex - 1]; 
    _safeTransferFrom(msg.sender, loyaltyCard, tokenId, 1, "");
  }

  /** 
   * @dev TODO 
   * 
   * 
  */ 


  /* getter functions */
  
  function getAvailableTokens(address loyaltyProgram) external view returns (uint256) {
    return  s_loyaltyProgramToTokenIds[msg.sender].length; 
  }
  // will get to some when testing. 
  // uri is already 1155 function.

}