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
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {LoyaltyToken} from "./LoyaltyToken.sol";
import {ERC6551Registry} from "./ERC6551Registry.sol";
import {SimpleERC6551Account} from "./SimpleERC6551Account.sol";
import {IERC6551Account}  from "../../src/interfaces/IERC6551Account.sol";

/* Type declarations */
struct Transaction {
      uint index; 
      uint points;
      uint timestamp;
      bool redeemed; 
  } 

// NB: Will implement as ERC721 because TBAs do not play nicely with ERC1155. 
contract LoyaltyProgram is ERC1155 {
  /* errors */
  error LoyaltyProgram__NoAccess(); 
  error LoyaltyProgram__OnlyOwner(); 
  error LoyaltyProgram__InSufficientPoints(); 
  error LoyaltyProgram__LoyaltyCardNotRecognised(); 
  error LoyaltyProgram__LoyaltyTokenNotRecognised(); 
  error LoyaltyProgram__TransactionIndexOutOfBounds(); 
  error LoyaltyProgram__NotOwnerLoyaltyCard(); 

  // Transaction[] public transactions; 

  /* State variables */
  uint256 public constant LOYALTY_POINTS = 0;
  uint256 public constant LOYALTY_CARDS = 1;

  address private s_owner; 
  mapping(address => bool) private s_LoyaltyTokens;
  mapping(address => bool) private s_LoyaltyCards;
  mapping(address => Transaction[] transactions) private s_Transactions; 
  uint256 private s_loyaltyCardCounter;
  ERC6551Registry public s_erc6551Registry;
  SimpleERC6551Account public s_erc6551Implementation;

  LoyaltyToken public selectedLoyaltyToken; 
  uint256[] public loyaltyCardId;
  uint256[] public mintNumberOf; 

  /* Events */
  event AddedLoyaltyToken(address indexed loyaltyToken);  
  event RemovedLoyaltyToken(address indexed loyaltyToken);

  /* Modifiers */ 
  modifier onlyOwner () {
    if (msg.sender != s_owner) {
      revert LoyaltyProgram__OnlyOwner(); 
    }
    _; 
  }

  /* constructor */
  constructor() ERC1155("https://ipfs.io/ipfs/QmcPwXFUayuEETYJvd3QaLU9Xtjkxte9rgBgfEjD2MBvJ5.json") { // still have to check if this indeed gives out same uri for each NFT minted. 
      s_owner = msg.sender;
      s_loyaltyCardCounter = 1;
      s_erc6551Registry = ERC6551Registry(0x02101dfB77FDE026414827Fdc604ddAF224F0921);
      s_erc6551Implementation = new SimpleERC6551Account(); 
 
      mintLoyaltyPoints(1e25); 
      mintLoyaltyCards(5);
  }

  /* public */
  function mintLoyaltyPoints(uint256 amountOfPoints) public onlyOwner {    
    _mint(s_owner, LOYALTY_POINTS, amountOfPoints, "");
  }

  function mintLoyaltyCards(uint256 numberOfLoyaltyCards) public onlyOwner {
    delete loyaltyCardId;
    delete mintNumberOf; 

    for (uint i; i < numberOfLoyaltyCards; i++) {
      loyaltyCardId.push(s_loyaltyCardCounter + i); 
      mintNumberOf.push(1); 
    }
    s_loyaltyCardCounter = s_loyaltyCardCounter + numberOfLoyaltyCards; 
    _mintBatch(msg.sender, loyaltyCardId, mintNumberOf, "");
    
    for (uint i; i < numberOfLoyaltyCards; i++) {
      address loyaltyCardAddress = _createTokenBoundAccount(s_loyaltyCardCounter + i);
      s_LoyaltyCards[loyaltyCardAddress] = true; 
    }
  }

  function transferLoyaltyPoints(address loyaltyCardAddress, uint256 numberLoyaltyPoints) public {
    if (s_LoyaltyCards[loyaltyCardAddress] != true) {
      revert LoyaltyProgram__LoyaltyCardNotRecognised(); 
    }
    _safeTransferFrom(s_owner, loyaltyCardAddress, 0, numberLoyaltyPoints, ""); 
  }

  function mintLoyaltyTokens(address nftLoyaltyAddress, uint256 numberOfTokens) public onlyOwner {
     LoyaltyToken(nftLoyaltyAddress).mintNft(numberOfTokens); 
  }

  function claimLoyaltyToken(
    address loyaltyToken, 
    uint256 loyaltyPoints,
    uint256 loyaltyCard,
    Transaction[] memory transactions 
    ) external {
      // checks
      if (balanceOf(msg.sender, loyaltyCard) != 0) {
        revert LoyaltyProgram__NotOwnerLoyaltyCard(); 
      }
      address loyaltyCardAddress = _retrieveTokenBoundAccount(loyaltyCard);
      if (loyaltyPoints < balanceOf(loyaltyCardAddress, 0)) {
        revert LoyaltyProgram__InSufficientPoints(); 
      }
      if (s_LoyaltyTokens[loyaltyToken] == false) {
        revert LoyaltyProgram__LoyaltyTokenNotRecognised(); 
      }

      // note: the next bit is ALSO external call. Security risk? 
      (bool success) = LoyaltyToken(loyaltyToken).requirementsNftMet(loyaltyCardAddress, loyaltyPoints, transactions); 

      // updating balances / interaction 
      if (success) {
        _safeTransferFrom(loyaltyCardAddress, s_owner, 0, loyaltyPoints, ""); // payment points
        for (uint i; i < transactions.length; i++) { // redeeming transactions 
          uint index = transactions[i].index; 
          s_Transactions[loyaltyCardAddress][index].redeemed = true; 
        }
      }

      // claiming Nft / external. 
      LoyaltyToken(loyaltyToken).claimNft(loyaltyCardAddress); 
  }

  function RedeemmLoyaltyToken(address loyaltyToken, uint256 loyaltyTokenId, uint256 loyaltyCard) external {
    if (balanceOf(msg.sender, loyaltyCard) != 0) {
      revert LoyaltyProgram__NotOwnerLoyaltyCard(); 
    }
    address loyaltyCardAddress = _retrieveTokenBoundAccount(loyaltyCard);
    LoyaltyToken(loyaltyToken).redeemNft(loyaltyCardAddress, loyaltyTokenId); 
  }

  function addLoyaltyToken(address loyaltyToken) public onlyOwner {
    // later checks will be added here. 
    s_LoyaltyTokens[loyaltyToken] = true; 
    emit AddedLoyaltyToken(loyaltyToken); 
  }

  function removeLoyaltyToken(address loyaltyToken) public onlyOwner {
    if (s_LoyaltyTokens[loyaltyToken] = false) {
      revert LoyaltyProgram__LoyaltyTokenNotRecognised();
    }
    s_LoyaltyTokens[loyaltyToken] = false;
    emit RemovedLoyaltyToken(loyaltyToken); 
  }

  /* internal */  
  /** 
   * @dev Only owner of Loyalty Program can transfer loyalty points freely to any address.  
   * @dev (This will later be updated to only adresses that are linked to NFT of Loyalty Program.) 
   * @dev Anyone else can only transfer to redeem contracts: contracts that convert points (and later also transactionEvents) into NFTs. 
   * @dev All params are the same from original. 
  */ 
  function _update(address from, address to, uint256[] memory ids, uint256[] memory value) internal override virtual {
    if (msg.sender != s_owner && s_LoyaltyTokens[to] == false) {
      revert LoyaltyProgram__NoAccess(); 
    }

    if (from == s_owner) {
      uint index = s_Transactions[to].length; 
      Transaction memory transaction = Transaction(
        index, value[0], block.timestamp, false
      ); 
      s_Transactions[to].push(transaction);
    }
    
    super._update(from, to, ids, value); 
  }

  function _createTokenBoundAccount (uint256 _loyaltyCardId) internal returns (address tokenBoundAccount) { 
      tokenBoundAccount = s_erc6551Registry.createAccount(
              address(s_erc6551Implementation),
              block.chainid,
              address(this),
              _loyaltyCardId,
              3947539732098357, 
              ""
          );

      return tokenBoundAccount; 
  }

  function _retrieveTokenBoundAccount (uint256 _loyaltyCardId) view internal returns (address tokenBoundAccount) { 
      tokenBoundAccount = s_erc6551Registry.account(
              address(s_erc6551Implementation),
              block.chainid,
              address(this),
              _loyaltyCardId,
              3947539732098357
          );

      return tokenBoundAccount; 
  }

  function _isOwnerTokenBoundAccount(address tokenBasedAccount, address consumer) view internal returns (bool isOwner) { 
      
      IERC6551Account accountInstance = IERC6551Account(payable(tokenBasedAccount));
      (, , uint256 tokenId) = accountInstance.token(); 

      return (balanceOf(consumer, tokenId) != 0);
  }


  /* private */  

 
  /* Getter functions */
  function getOwner() external view returns (address) {
    return s_owner; 
  } 

  function getTransactions(address customer) external view returns (Transaction[] memory) {
    return s_Transactions[customer]; 
  }

  function getLoyaltyToken(address loyaltyToken) external view returns (bool) {
    return s_LoyaltyTokens[loyaltyToken]; 
  }

  function getNumberLoyaltyCardsMinted() external view returns (uint256) {
    return s_loyaltyCardCounter; 
  }
}




