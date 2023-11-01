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

contract LoyaltyNft is ERC721 {

  /* errors */ 
  error LoyaltyNft__IncorrectNftContract();
  error LoyaltyNft__NftNotOwnedByConsumer(); 
  error LoyaltyNft__NoPointsOrTransactionsReceived(); 
  error LoyaltyNft__InsufficientPoints(); 
  error LoyaltyNft__InsufficientTransactions(); 
  error LoyaltyNft__InsufficientTransactionsAndPoints(); 
  
  /* Type declarations */  
  struct LoyaltyNftData { 
    address program; 
    string tokenUri; 
  }

  /* State variables */ 
  mapping (uint256 => LoyaltyNftData) private s_tokenIdToLoyaltyNft; 
  mapping (address => uint256[]) private s_consumersToTokenIds; 
  uint256 private s_tokenCounter;
  string  public s_loyaltyNftUri; 

  /* Events */
  event RedeemedNft(uint256 indexed tokenId);  

  /* Modifiers */
  modifier onlyCorrectLoyaltyProgram (uint256 tokenId) {
    if (s_tokenIdToLoyaltyNft[tokenId].program != msg.sender) {
      revert LoyaltyNft__IncorrectNftContract(); 
    }
    _; 
  }

  /* FUNCTIONS: */
  /* constructor */
  constructor(string memory loyaltyNftUri) ERC721("FreeCoffee", "FC") {
    s_tokenCounter = 0;
    s_loyaltyNftUri = loyaltyNftUri; 
  }

  /** 
   * @dev TODO
   * 
   * 
  */ 
  function redeemNft(address consumer, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    if (s_tokenIdToLoyaltyNft[tokenId].program != msg.sender) {
      revert LoyaltyNft__IncorrectNftContract(); 
    }
    if (owner != consumer) {
      revert LoyaltyNft__NftNotOwnedByConsumer(); 
    }

    s_tokenIdToLoyaltyNft[tokenId] = LoyaltyNftData(address(0), ""); 
    _burn(tokenId); 

    emit RedeemedNft(tokenId); 
  }

  function tokenURI(
    uint256 tokenId
    ) public view override returns (string memory) {
      return s_tokenIdToLoyaltyNft[tokenId].tokenUri; 
    } 

  // function claimNft(
  //   address consumer, 
  //   uint256 loyaltyPoints
  //   ) public returns (bool) {
  //     bool success = false; 
  //     Transaction[] emptyTransactions; 
  //     emptyTransactions = [Transaction(0, 0, false)]; 

  //     _updateClaimNft(consumer, loyaltyPoints, [emptyTransactions]);
  //     success = true;  
  //     return success; 
  // }

  function claimNft(
    address consumer, 
    uint256 loyaltyPoints, 
    Transaction[] memory selectedTansactions
    ) public returns (bool) {
      bool success = false; 
      _updateClaimNft(consumer, loyaltyPoints, selectedTansactions);
      success = true;  
      return success; 
  }


  /* internal */
  /** 
   * @dev TODO 
   * 
   * 
  */ 
  function _updateClaimNft(
    address consumer, 
    uint256 loyaltyPoints, 
    Transaction[] memory selectedTansactions
    ) internal virtual {
      if (loyaltyPoints == 0 && selectedTansactions.length == 0) { // this should later be updated to check if ALSO no transaction events were received. 
        revert LoyaltyNft__NoPointsOrTransactionsReceived(); 
      }

      s_tokenIdToLoyaltyNft[s_tokenCounter] = LoyaltyNftData(msg.sender, s_loyaltyNftUri);
      _safeMint(consumer, s_tokenCounter); 
      s_tokenCounter = s_tokenCounter + 1;
  }

  /* getter functions */
  function getLoyaltyNftData(uint256 tokenId) external view returns (LoyaltyNftData memory) {
    return s_tokenIdToLoyaltyNft[tokenId]; 
  }

  function getNftIdsOf(address consumer) external view returns (uint256[] memory) {
    return s_consumersToTokenIds[consumer]; 
  }

}