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

  /* Type declarations */
  string public constant FREE_COFFEE_URI = "ipfs://QmTzKTU5VQmt3aDJSjBfWhkpzSr7GDPaL3ModEHbmiNRE7"; 

  struct LoyaltyNftData { 
    address program; 
    string tokenUri; 
  }

  /* State variables */ 
  mapping (uint256 => LoyaltyNftData) private s_tokenIdToLoyaltyNft; 
  
  /* Events */
  event ClaimedNft(uint256 indexed tokenId);  
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
  constructor() ERC721("FreeCoffee", "FC") {

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
  function claimNft(address consumer) public returns (uint256) {
    uint256 tokenId = _pseudoRandomTokenId();
  
    s_tokenIdToLoyaltyNft[tokenId] = LoyaltyNftData(msg.sender, FREE_COFFEE_URI);
    // s_tokenIdToUri[tokenId] = tokenUri; 
    // s_tokenIdToProgram[tokenId] = msg.sender; 
    _safeMint(consumer, tokenId); 

    emit ClaimedNft(tokenId); 
    return tokenId;
  }


  /** 
   * @dev TODO
   * 
   * 
  */ 
  function redeemNft(uint256 tokenId) public returns (bool) {
    bool success = false; 
    
    if (s_tokenIdToLoyaltyNft[tokenId].program != msg.sender) {
      revert LoyaltyNft__IncorrectNftContract(); 
    }
    
    s_tokenIdToLoyaltyNft[tokenId] = LoyaltyNftData(address(0), ""); 
    _burn(tokenId); 

    success = true; 
    emit RedeemedNft(tokenId); 
    return success; 
  }

  function tokenURI(
    uint256 tokenId
    ) public view override returns (string memory) {
      return s_tokenIdToLoyaltyNft[tokenId].tokenUri; 
    } 

  
  /* internal */
  /** 
   * @dev TODO
   * 
   * 
  */ 
  // from: https://medium.com/coinmonks/how-to-generate-random-numbers-in-solidity-16950cb2261d
  function _pseudoRandomTokenId() internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp
    )));
  }

}