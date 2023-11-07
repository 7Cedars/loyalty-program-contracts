// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// NB: see ERC1155 contract from openZeppelin for good example of how to use natspecs. 
// TODO: implement and describe accordingly.  

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract LoyaltyToken is ERC1155 {

  /* errors */ 
  error LoyaltyToken__LoyaltyProgramNotRecognised(address loyaltyToken);
  error LoyaltyToken__NftNotOwnedByloyaltyCard(address loyaltyToken); 
  error LoyaltyToken__NoTokensAvailable(address loyaltyToken); 
  error LoyaltyToken__InsufficientPoints(address loyaltyToken);

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

  /** 
   * @dev TODO 
   * 
   * 
  */ 
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
  function requirementsLoyaltyTokenMet(
    address, // loyaltyCard
    uint256 // loyaltypoints
    ) public virtual returns (bool success) {
      
      // Here NFT specific requirements are inserted. 

      return true; 
  }
  
  /** 
   * @dev 
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
  function redeemNft(address loyaltyCard, uint256 tokenId) public {
    if (balanceOf(loyaltyCard, tokenId) == 0) {
      revert LoyaltyToken__NftNotOwnedByloyaltyCard(address(this)); 
    }
    if (s_tokenIdToLoyaltyProgram[tokenId] != msg.sender) {
      revert LoyaltyToken__LoyaltyProgramNotRecognised(address(this)); 
    }

    _safeTransferFrom(loyaltyCard, address(0), tokenId, 1, ""); // emits singleTransfer event. 
  }


  /* getter functions */
  
  function getAvailableTokens() external view returns (uint256) {
    return  s_loyaltyProgramToTokenIds[msg.sender].length; 
  }
  // will get to some when testing. 
  // uri is already 1155 function.

}