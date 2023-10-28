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

/* imports */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LoyaltyAccount is ERC20 {
  /* errors */
  error LoyaltyAccount__NoAccess(); 
  error LoyaltyAccount__OnlyOwner(); 

  /* State variables */
  address private s_owner; 
  mapping(address => bool) private s_RedeemNFTContracts; 

  /* Events */
  
  /* Modifiers */ 
  modifier onlyOwner () {
    if (msg.sender != s_owner) {
      revert LoyaltyAccount__OnlyOwner(); 
    }
    _; 
  }

  /* constructor */
  constructor(uint256 initialSupply) ERC20("LoyaltyPoints", "LPX") {
      s_owner = msg.sender; 
      _mint(msg.sender, initialSupply);
  }

  /* public */
  function addRedeemContract(address redeemContract) public {
    s_RedeemNFTContracts[redeemContract] = true; 
  }

  function removeRedeemContract(address redeemContract) public {
    s_RedeemNFTContracts[redeemContract] = false; 
  }

  /* internal */   
  /** 
   * @dev Only owner of Loyalty Program can transfer loyalty points freely to any address.  
   * @dev (This will later be updated to only adresses that are linked to NFT of Loyalty Program.) 
   * @dev Anyone else can only transfer to redeem contracts: contracts that convert points (and later also transactionEvents) into NFTs. 
   * @dev All params are the same from original. 
  */ 
  function _update(address from, address to, uint256 value) internal override virtual {
    if (msg.sender != s_owner && s_RedeemNFTContracts[to] == false) {
      revert LoyaltyAccount__NoAccess(); 
    }

    super._update(from, to, value); 
  }

  /* Getter functions */
  function getOwner() external view returns (address) {
    return s_owner; 
  } 


}




