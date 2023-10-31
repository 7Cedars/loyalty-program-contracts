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
import {LoyaltyNft} from "./LoyaltyNft.sol";

contract LoyaltyProgram is ERC20 {
  /* errors */
  error LoyaltyProgram__NoAccess(); 
  error LoyaltyProgram__OnlyOwner(); 
  error LoyaltyProgram__RedeemContractAbsent(); 

  /* Type declarations */
  struct Transaction {
        uint256 points;
        uint256 timestamp;
        bool redeemed; 
    }

  /* State variables */
  address private s_owner; 
  mapping(address => bool) private s_RedeemContracts; 
  mapping(address => Transaction[]) private s_Transactions; 
  LoyaltyNft public selectedLoyaltyNft; 

  /* Events */
  event AddedRedeemContract(address indexed redeemContract);  
  event RemovedRedeemContract(address indexed redeemContract);

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
  function addRedeemContract(address redeemContract) public onlyOwner {
    // later checks will be added here. 
    s_RedeemContracts[redeemContract] = true; 
    emit AddedRedeemContract(redeemContract); 
  }

  function removeRedeemContract(address redeemContract) public onlyOwner {
    if (s_RedeemContracts[redeemContract] = false) {
      revert LoyaltyProgram__RedeemContractAbsent();
    }
    s_RedeemContracts[redeemContract] = false;
    emit RemovedRedeemContract(redeemContract); 
  }

  function mintLoyaltyPoints(uint256 amount) public onlyOwner {
    _mint(s_owner, amount); 
  }

  // NB Need to use transferFrom & allowance -- when it comes to redeem NFTs  

  /* internal */  
  /** 
   * @dev Only owner of Loyalty Program can transfer loyalty points freely to any address.  
   * @dev (This will later be updated to only adresses that are linked to NFT of Loyalty Program.) 
   * @dev Anyone else can only transfer to redeem contracts: contracts that convert points (and later also transactionEvents) into NFTs. 
   * @dev All params are the same from original. 
  */ 
  function _update(address from, address to, uint256 value) internal override virtual {
    if (msg.sender != s_owner && s_RedeemContracts[to] == false) {
      revert LoyaltyProgram__NoAccess(); 
    }

    if (from == s_owner) {
      Transaction memory transaction = Transaction(
        value, block.timestamp, false
      ); 
      s_Transactions[to].push(transaction);
    }
    
    super._update(from, to, value); 
  }

  /* private */  

 
  /* Getter functions */
  function getOwner() external view returns (address) {
    return s_owner; 
  } 

  function getTransactions(address customer) external view returns (Transaction[] memory) {
    return s_Transactions[customer]; 
  }

  function getRedeemContract(address redeemContract) external view returns (bool) {
    return s_RedeemContracts[redeemContract]; 
  }
}




