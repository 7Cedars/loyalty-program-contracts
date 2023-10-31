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

contract LoyaltyNft is ERC721 {

  /* errors */ 
  error LoyaltyNft__IncorrectNftContract();
  error LoyaltyNft__NftNotOwnedByConsumer(); 
  error LoyaltyNft__InsufficientPoints(); 

  /* Type declarations */  
  struct LoyaltyNftData { 
    address program; 
    string tokenUri; 
  }

  /* State variables */ 
  mapping (uint256 => LoyaltyNftData) private s_tokenIdToLoyaltyNft; 
  mapping (address => uint256[]) private s_consumersToTokenIds; 
  uint256 private s_tokenCounter;
  uint256 public s_loyaltyNftPrice; // 2500
  string  public s_loyaltyNftUri; //  = "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7"; 

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
  constructor(uint256 loyaltyNftPrice, string memory loyaltyNftUri) ERC721("FreeCoffee", "FC") {
    s_tokenCounter = 0;
    s_loyaltyNftPrice = loyaltyNftPrice; 
    s_loyaltyNftUri = loyaltyNftUri; 
  }

  // why not have this claimNFT function take a tokenId AND loyalty program address? 
  // I can add a mapping 'program' in addition to 'owner'. 
  // This means that all existing functionality remains intact (NFTs can be traded, etc) 
  // Except that it enables a check on what program they have been minted from... 
  // This also enables NFTs to be redeemed from claim programs that have been discontinued.
   /** 
   * @dev TODO 
   * 
   * 
  */ 
 // should be internal virtual..  
  function claimNft(address consumer, uint256 loyaltyPoints) public {
    if (loyaltyPoints < s_loyaltyNftPrice) {
      revert LoyaltyNft__InsufficientPoints(); 
    }

    s_tokenIdToLoyaltyNft[s_tokenCounter] = LoyaltyNftData(msg.sender, s_loyaltyNftUri);
    _safeMint(consumer, s_tokenCounter); 
    s_tokenCounter = s_tokenCounter + 1;
  }


  /** 
   * @dev TODO
   * 
   * 
  */ 
  function redeemNft(uint256 tokenId, address consumer) public {
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

  /* internal */

  /* getter functions */
  function getLoyaltyNftData(uint256 tokenId) external view returns (LoyaltyNftData memory) {
    return s_tokenIdToLoyaltyNft[tokenId]; 
  }

  function getNftIdsOf(address consumer) external view returns (uint256[] memory) {
    return s_consumersToTokenIds[consumer]; 
  }

}