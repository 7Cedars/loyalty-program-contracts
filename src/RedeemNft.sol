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

contract RedeemNft is ERC721 {

  /* errors */ 
  error RedeemNft__IncorrectRedeemContract();

  /* Type declarations */


  /* State variables */ 
  // NB: I might want to combine this into a struct. -- see later. 
  mapping (uint256 => address) private s_tokenIdToProgram; 
  mapping (uint256 => string) private s_tokenIdToUri; 
  
  
  /* Events */
  event ClaimedNft(uint256 indexed tokenId);  
  event RedeemedNft(uint256 indexed tokenId);  

  /* Modifiers */
  modifier onlyCorrectLoyaltyProgram (uint256 tokenId) {
    if (s_tokenIdToProgram[tokenId] != msg.sender) {
      revert RedeemNft__IncorrectRedeemContract(); 
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
  function claimNft(address consumer, string memory tokenUri) public returns (uint256) {
    uint256 tokenId = _pseudoRandomTokenId(); 
    s_tokenIdToUri[tokenId] = tokenUri; 
    s_tokenIdToProgram[tokenId] = msg.sender; 
    _safeMint(consumer, tokenId); 

    emit ClaimedNft(tokenId); 
    return tokenId;
  }


  /** 
   * @dev TODO
   * 
   * 
  */ 
  function redeemNft(uint256 tokenId) public {
    if (s_tokenIdToProgram[tokenId] != msg.sender) {
      revert RedeemNft__IncorrectRedeemContract(); 
    }
    
    s_tokenIdToProgram[tokenId] = address(0); 
    _burn(tokenId); 

    emit RedeemedNft(tokenId); 
  }

  function tokenURI(
    uint256 tokenId
    ) public view override returns (string memory) {
      return s_tokenIdToUri[tokenId]; 
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