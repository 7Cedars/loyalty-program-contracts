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

contract LoyaltyProgram is ERC20 {
  /* errors */
  error LoyaltyProgram__NoAccess(); 
  error LoyaltyProgram__OnlyOwner(); 
  error LoyaltyProgram__RedeemContractNotFound(); 

  /* State variables */
  address private s_owner; 

  /** 
   * @dev note double logging of redeem contracts. 
   * @dev this is because adding and removing does not happen very often. 
   * @dev but calling list of all redeem contracts is a necessity for frontend + 
   * @dev chep check if redeemContract is being tranferred to (see _update function) as well. 
   * @dev seemed to be the most gas efficieng but sohould check later. 
   * */ 
  address[] private s_RedeemContracts; 
  mapping(address => bool) private s_RedeemContractsMap; 

  /* Events */
  
  /* Modifiers */ 
  modifier onlyOwner () {
    if (msg.sender != s_owner) {
      revert LoyaltyProgram__OnlyOwner(); 
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
    // later checks will be added here. 
    s_RedeemContracts.push(redeemContract); 
    s_RedeemContractsMap[redeemContract] = true; 
  }

  /** 
   * @dev Redeem contracts needs to be a list (see getRedeemContracts function below).   
   * @dev To delete a contract, it loops through the arrat. 
   * @dev When element == redeemContract to be deleted, the last element of the array is moved in its place,
   * @dev and last element is popped. 
  */ 
  function removeRedeemContract(address redeemContract) public {
    s_RedeemContractsMap[redeemContract] = false; 
    for (uint256 i = 0; i < s_RedeemContracts.length; i++) {
          if (s_RedeemContracts[i] == redeemContract) {
            s_RedeemContracts[i] = s_RedeemContracts[s_RedeemContracts.length - 1];
            s_RedeemContracts.pop(); 
          }
        }
    revert LoyaltyProgram__RedeemContractNotFound(); 
  }

  /* internal */  
  /** 
   * @dev Only owner of Loyalty Program can transfer loyalty points freely to any address.  
   * @dev (This will later be updated to only adresses that are linked to NFT of Loyalty Program.) 
   * @dev Anyone else can only transfer to redeem contracts: contracts that convert points (and later also transactionEvents) into NFTs. 
   * @dev All params are the same from original. 
  */ 
  function _update(address from, address to, uint256 value) internal override virtual {
    if (msg.sender != s_owner && s_RedeemContractsMap[to] == false) {
      revert LoyaltyProgram__NoAccess(); 
    }

    super._update(from, to, value); 
  }

  /* private */  

 
  /* Getter functions */
  function getOwner() external view returns (address) {
    return s_owner; 
  } 

  function getRedeemContracts() external view returns (address[] memory) {
    return s_RedeemContracts; 
  } 

}




