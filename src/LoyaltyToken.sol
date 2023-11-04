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

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Transaction} from "./LoyaltyProgram.sol";

contract LoyaltyToken is ERC721 {

  /* errors */ 
  error LoyaltyToken__IncorrectNftContract(address loyaltyToken);
  error LoyaltyToken__NftNotOwnedByConsumer(address loyaltyToken); 
  error LoyaltyToken__MaxNftsToMint25Exceeded(address loyaltyToken);
  error LoyaltyToken__NoNftsAvailable(address loyaltyToken); 
  error LoyaltyToken__InsufficientPoints(address loyaltyToken); 
  error LoyaltyToken__InsufficientTransactions(address loyaltyToken); 
  error LoyaltyToken__InsufficientTransactionsAndPoints(address loyaltyToken); 
  
  /* Type declarations */  
  struct LoyaltyTokenData { 
    address program; 
    string tokenUri; 
  }

  /* State variables */ 
  mapping (uint256 => LoyaltyTokenData) private s_tokenIdToLoyaltyToken; 
  uint256 private s_tokenCounter;
  string  public s_loyaltyTokenUri; 

  /* Events */
  event RedeemedNft(uint256 indexed tokenId);  

  /* Modifiers */
  modifier onlyCorrectLoyaltyProgram (uint256 tokenId) {
    if (s_tokenIdToLoyaltyToken[tokenId].program != msg.sender) {
      revert LoyaltyToken__IncorrectNftContract(address(this)); 
    }
    _; 
  }

  /* FUNCTIONS: */
  /* constructor */
  constructor(string memory loyaltyTokenUri) ERC721("LoyaltyToken", "LPN") {
    s_tokenCounter = 0;
    s_loyaltyTokenUri = loyaltyTokenUri; 
  }

  /** 
   * @dev TODO
   * 
   * 
  */ 
  function redeemNft(address consumer, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    if (s_tokenIdToLoyaltyToken[tokenId].program != msg.sender) {
      revert LoyaltyToken__IncorrectNftContract(address(this)); 
    }
    if (owner != consumer) {
      revert LoyaltyToken__NftNotOwnedByConsumer(address(this)); 
    }

    s_tokenIdToLoyaltyToken[tokenId] = LoyaltyTokenData(address(0), ""); 
    _burn(tokenId); 

    emit RedeemedNft(tokenId); 
  }

  function tokenURI(
    uint256 tokenId
    ) public view override returns (string memory) {
      return s_tokenIdToLoyaltyToken[tokenId].tokenUri; 
    } 

  /** 
   * @dev TODO 
   * 
   * 
  */ 
  function requirementsNftMet(address, uint256, Transaction[] memory
    ) public virtual returns (bool success) {
      
      // Here NFT specific requirements are inserted. 

      if (balanceOf(msg.sender) == 0) {
        revert LoyaltyToken__NoNftsAvailable(address(this)); 
      }
      return true; 
  }
  
  /** 
   * @dev TODO 
   * 
   * 
  */ 
  function claimNft(address consumer) public {
    uint tokenId = s_tokenCounter - balanceOf(msg.sender); 
    safeTransferFrom(msg.sender, consumer, tokenId);
  }

  /** 
   * @dev TODO 
   * 
   * 
  */ 
  function mintNft(uint256 numberOfNfts) public {
    if (numberOfNfts > 100) {
      revert LoyaltyToken__MaxNftsToMint25Exceeded(address(this)); 
    }

    for (uint i = 0; i < numberOfNfts; i++) {        
      _safeMint(msg.sender, s_tokenCounter);
      s_tokenIdToLoyaltyToken[s_tokenCounter] = LoyaltyTokenData(msg.sender, s_loyaltyTokenUri); 
      s_tokenCounter = s_tokenCounter + 1;
    }
  }

  /* internal */


  /* getter functions */
  function getLoyaltyTokenData(uint256 tokenId) external view returns (LoyaltyTokenData memory) {
    return s_tokenIdToLoyaltyToken[tokenId]; 
  }

}