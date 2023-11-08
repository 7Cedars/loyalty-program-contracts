// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/* imports */
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {LoyaltyToken} from "./LoyaltyToken.sol";
import {ERC6551Registry} from "./ERC6551Registry.sol";
import {SimpleERC6551Account} from "./SimpleERC6551Account.sol";
import {IERC6551Account}  from "../src/interfaces/IERC6551Account.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LoyaltyProgram is ERC1155, ReentrancyGuard {
  
  /* errors */
  error LoyaltyProgram__NoAccess(); 
  error LoyaltyProgram__OnlyOwner(); 
  error LoyaltyProgram__InSufficientPoints(); 
  error LoyaltyProgram__LoyaltyCardNotRecognised(); 
  error LoyaltyProgram__LoyaltyTokenNotRecognised(); 
  error LoyaltyProgram__NotOwnerLoyaltyCard(); 
  error LoyaltyProgram__CardCanOnlyReceivePoints(); 
  error LoyaltyProgram__LoyaltyCardNotAvailable(); 

  /* State variables */
  uint256 public constant LOYALTY_POINTS = 0;

  address private s_owner; 
  mapping(address => uint256) private s_LoyaltyTokens; // 0 = false & 1 = true. 
  mapping(address => uint256) private s_LoyaltyCards; // 0 = false & 1 = true.
  // NB! I can get available tokens from loyaltyTokenAddress! 
  uint256 private s_loyaltyCardCounter;
  ERC6551Registry public s_erc6551Registry;
  SimpleERC6551Account public s_erc6551Implementation;

  /* Events */
  // Have to check which events I can take out because they already emit events... 
  event AddedLoyaltyTokenContract(address indexed loyaltyToken);  
  event RemovedLoyaltyTokenContract(address indexed loyaltyToken);
  event MintedLoyaltyTokens(address loyaltyTokenAddress, uint256 numberOfTokens); 
  event ClaimedLoyaltyToken(address loyaltyToken, uint256 tokenId, address loyaltyCardAddress); 
  event RedeemedLoyaltyToken(address loyaltyToken, uint256 loyaltyTokenId, address loyaltyCardAddress); 

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
      s_loyaltyCardCounter = 0;
      s_erc6551Registry = new ERC6551Registry();
      s_erc6551Implementation = new SimpleERC6551Account(); 
 
      mintLoyaltyPoints(1e25); 
      mintLoyaltyCards(25);
  }

   /* public */
  function mintLoyaltyCards(uint256 numberOfLoyaltyCards) public onlyOwner {
    uint256[] memory loyaltyCardIds = new uint256[](numberOfLoyaltyCards); 
    uint256[] memory mintNfts = new uint256[](numberOfLoyaltyCards); 
    uint256 counter = s_loyaltyCardCounter; 

    // note that I log these addresses internally BEFORE they have actually been minted. 
    for (uint i; i < numberOfLoyaltyCards; i++) { // i starts at 0.... right? TEST! 
      counter = counter + 1; 
      loyaltyCardIds[i] = counter;
      mintNfts[i] = 1; 
      address loyaltyCardAddress = _createTokenBoundAccount(counter);
      s_LoyaltyCards[loyaltyCardAddress] = 1; 
    }

    _mintBatch(msg.sender, loyaltyCardIds, mintNfts, "");
    s_loyaltyCardCounter = s_loyaltyCardCounter + numberOfLoyaltyCards; 
  }

  // function giftLoyaltyCard(address consumer, uint256 loyaltyCardId) public onlyOwner {
  //   if (balanceOf(s_owner, loyaltyCardId) == 0) {
  //     revert LoyaltyProgram__LoyaltyCardNotAvailable(); 
  //   }
  //   safeTransferFrom(s_owner, consumer, loyaltyCardId, 1, "");
  // }

  function mintLoyaltyPoints(uint256 amountOfPoints) public onlyOwner {    
    _mint(s_owner, LOYALTY_POINTS, amountOfPoints, "");
  }

  // function giftLoyaltyPoints(address loyaltyCardAddress, uint256 numberLoyaltyPoints) public onlyOwner {
  //   if (s_LoyaltyCards[loyaltyCardAddress] != 1) {
  //     revert LoyaltyProgram__LoyaltyCardNotRecognised(); 
  //   }
  //   _safeTransferFrom(s_owner, loyaltyCardAddress, 0, numberLoyaltyPoints, "");   
  // }

  function addLoyaltyTokenContract(address loyaltyToken) public onlyOwner {
    // later checks will be added here. 
    s_LoyaltyTokens[loyaltyToken] = 1; 
    emit AddedLoyaltyTokenContract(loyaltyToken); 
  }

  function removeLoyaltyTokenContract(address loyaltyToken) public onlyOwner {
    if (s_LoyaltyTokens[loyaltyToken] == 0 ) {
      revert LoyaltyProgram__LoyaltyTokenNotRecognised();
    }
    s_LoyaltyTokens[loyaltyToken] = 0;
    emit RemovedLoyaltyTokenContract(loyaltyToken); 
  }

  function mintLoyaltyTokens(
    address loyaltyTokenAddress, 
    uint256 numberOfTokens
    ) public onlyOwner nonReentrant {
      LoyaltyToken(loyaltyTokenAddress).mintLoyaltyTokens(numberOfTokens); 
      emit MintedLoyaltyTokens(loyaltyTokenAddress, numberOfTokens); 
  }

  function claimLoyaltyToken(
    address loyaltyToken, 
    uint256 loyaltyPoints,
    uint256 loyaltyCard
    ) external nonReentrant {
      // checks
      if (balanceOf(msg.sender, loyaltyCard) != 0) {
        revert LoyaltyProgram__NotOwnerLoyaltyCard(); 
      }
      address loyaltyCardAddress = _retrieveTokenBoundAccount(loyaltyCard);
      if (loyaltyPoints < balanceOf(loyaltyCardAddress, 0)) {
        revert LoyaltyProgram__InSufficientPoints(); 
      }
      if (s_LoyaltyTokens[loyaltyToken] == 0) {
        revert LoyaltyProgram__LoyaltyTokenNotRecognised(); 
      }

      // note: the next bit is ALSO external call. Security risk? Hence added nonReentrant... 
      (bool success) = LoyaltyToken(loyaltyToken).requirementsLoyaltyTokenMet(loyaltyCardAddress, loyaltyPoints); 

      // updating balances / interaction 
      if (success) { _safeTransferFrom(loyaltyCardAddress, s_owner, 0, loyaltyPoints, ""); }

      // claiming Nft / external. 
      uint256 tokenId = LoyaltyToken(loyaltyToken).claimNft(loyaltyCardAddress); 

      emit ClaimedLoyaltyToken(loyaltyToken, tokenId, loyaltyCardAddress); 
  }

  function RedeemmLoyaltyToken(
    address loyaltyToken, 
    uint256 loyaltyTokenId, 
    uint256 loyaltyCard
    ) external nonReentrant {
      if (balanceOf(msg.sender, loyaltyCard) != 0) {
        revert LoyaltyProgram__NotOwnerLoyaltyCard(); 
      }
      address loyaltyCardAddress = _retrieveTokenBoundAccount(loyaltyCard);
      LoyaltyToken(loyaltyToken).redeemNft(loyaltyCardAddress, loyaltyTokenId); 

      emit RedeemedLoyaltyToken(loyaltyToken, loyaltyTokenId, loyaltyCardAddress); 
  }

  // replace safeTransferFrom function. as _msgSender gave odd otuput? 
  function safeTransferFrom (
    address from, 
    address to, 
    uint256 id, 
    uint256 value, 
    bytes memory data) 
    public override {
        address sender = msg.sender;
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert ERC1155MissingApprovalForAll(sender, from);
        }
        _safeTransferFrom(from, to, id, value, data);
    }

  /* internal */  
  /** 
   * @dev Loyalty points and tokens can only transferred to and from
   *  - the owner of Loyalty Program (the vendor).  
   *  - loyalty token contracts.  
   *  - other loyalty cards. 
   * @dev All params are the same from original. 
  */ 
  function _update(address from, address to, uint256[] memory ids, uint256[] memory value) internal override virtual {
    if (
      to != s_owner && 
      from != s_owner && 
      s_LoyaltyTokens[to] == 0 && 
      s_LoyaltyCards[to] == 0
      ) {
        revert LoyaltyProgram__NoAccess(); 
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
 
  /* Getter functions */
  function getOwner() external view returns (address) {
    return s_owner; 
  }

  function getLoyaltyToken(address loyaltyToken) external view returns (uint256) {
    return s_LoyaltyTokens[loyaltyToken]; 
  }

  function getNumberLoyaltyCardsMinted() external view returns (uint256) {
    return s_loyaltyCardCounter; 
  }
}


// This is a keeper for myself: structure contract // 
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
