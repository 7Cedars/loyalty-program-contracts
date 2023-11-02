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

/* Type declarations */
struct Transaction {
      uint index; 
      uint points;
      uint timestamp;
      bool redeemed; 
  } 

contract LoyaltyProgram is ERC20 {
  /* errors */
  error LoyaltyProgram__NoAccess(); 
  error LoyaltyProgram__OnlyOwner(); 
  error LoyaltyProgram__InSufficientPoints(); 
  error LoyaltyProgram__LoyaltyNftNotRecognised(); 
  error LoyaltyProgram__TransactionIndexOutOfBounds(); 

  // Transaction[] public transactions; 

  /* State variables */
  uint256 constant INITIAL_SUPPLY = 1e25; 
  address private s_owner; 
  mapping(address => bool) private s_LoyaltyNfts; 
  mapping(address => Transaction[] transactions) private s_Transactions; 
  LoyaltyNft public selectedLoyaltyNft; 

  /* Events */
  event AddedLoyaltyNft(address indexed loyaltyNft);  
  event RemovedLoyaltyNft(address indexed loyaltyNft);

  /* Modifiers */ 
  modifier onlyOwner () {
    if (msg.sender != s_owner) {
      revert LoyaltyProgram__OnlyOwner(); 
    }
    _; 
  }

  /* constructor */
  constructor() ERC20("LoyaltyPoints", "LPX") {
      s_owner = msg.sender; 
      _mint(msg.sender, INITIAL_SUPPLY);
  }

  /* public */
  function mintLoyaltyPoints(uint256 amountOfPoints) public onlyOwner {
    _mint(s_owner, amountOfPoints); 
  }

  function mintNfts(address nftAddress, uint256 numberOfNfts) public onlyOwner {
     LoyaltyNft(nftAddress).mintNft(numberOfNfts); 
  }

  function claimSelectedNft(
    address nftAddress, 
    uint256 loyaltyPoints,
    Transaction[] memory transactions 
    ) external {
      // checks
      if (s_LoyaltyNfts[nftAddress] == false) {
        revert LoyaltyProgram__LoyaltyNftNotRecognised(); 
      }
      if (loyaltyPoints < balanceOf(msg.sender)) {
        revert LoyaltyProgram__InSufficientPoints(); 
      }
      (bool success) = LoyaltyNft(nftAddress).requirementsNftMet(msg.sender, loyaltyPoints, transactions); 

      // updating balances
      if (success) {
        transferFrom(msg.sender, s_owner, loyaltyPoints); // payment points
        for (uint i; i < transactions.length; i++) { // redeeming transaction 
          uint index = transactions[i].index; 
          s_Transactions[msg.sender][index].redeemed = true; 
        }
      }

      // claiming Nft. 
      LoyaltyNft(nftAddress).claimNft(msg.sender); 
  }

  function RedeemmSelectedNft(address loyaltyNft, uint256 tokenId) external {
    selectedLoyaltyNft = LoyaltyNft(loyaltyNft); 
    selectedLoyaltyNft.redeemNft(msg.sender, tokenId); 
  }

  function addLoyaltyNft(address loyaltyNft) public onlyOwner {
    // later checks will be added here. 
    s_LoyaltyNfts[loyaltyNft] = true; 
    emit AddedLoyaltyNft(loyaltyNft); 
  }

  function removeLoyaltyNft(address loyaltyNft) public onlyOwner {
    if (s_LoyaltyNfts[loyaltyNft] = false) {
      revert LoyaltyProgram__LoyaltyNftNotRecognised();
    }
    s_LoyaltyNfts[loyaltyNft] = false;
    emit RemovedLoyaltyNft(loyaltyNft); 
  }

  /* internal */  
  /** 
   * @dev Only owner of Loyalty Program can transfer loyalty points freely to any address.  
   * @dev (This will later be updated to only adresses that are linked to NFT of Loyalty Program.) 
   * @dev Anyone else can only transfer to redeem contracts: contracts that convert points (and later also transactionEvents) into NFTs. 
   * @dev All params are the same from original. 
  */ 
  function _update(address from, address to, uint256 value) internal override virtual {
    if (msg.sender != s_owner && s_LoyaltyNfts[to] == false) {
      revert LoyaltyProgram__NoAccess(); 
    }

    if (from == s_owner) {
      uint index = s_Transactions[to].length; 
      Transaction memory transaction = Transaction(
        index, value, block.timestamp, false
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

  function getLoyaltyNft(address loyaltyNft) external view returns (bool) {
    return s_LoyaltyNfts[loyaltyNft]; 
  }
}




