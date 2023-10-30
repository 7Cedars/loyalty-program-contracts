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

contract RedeemNftA is ERC721 {

  error ERC721__TokenIdExists(uint256 tokenId); 

  constructor() ERC721("FreeCoffee", "FC") {

  }

  // from: https://medium.com/coinmonks/how-to-generate-random-numbers-in-solidity-16950cb2261d
  function _pseudoRandomTokenId() internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp
    )));
  }

  // why not have this claimNFT function take a tokenId AND loyalty program address? 
  // I can add a mapping 'program' in addition to 'owner'. 
  // This means that all existing functionality remains intact (NFTs can be traded, etc) 
  // Except that it enables a check on what program they have been minted from... 
  // This also enables NFTs to be redeemed from claim programs that have been discontinued.  
  function claimNft() public {}

  function tokenURI(
    uint256 tokenId
    ) public view override returns (string memory) {} 



}