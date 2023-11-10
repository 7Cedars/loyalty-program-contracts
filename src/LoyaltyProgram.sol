// When reviewing this code, check: https://github.com/transmissions11/solcurity
// see also: https://github.com/nascentxyz/simple-security-toolkit

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/* imports */
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {LoyaltyToken} from "./LoyaltyToken.sol";
import {ERC6551Registry} from "./ERC6551Registry.sol";
import {ERC6551Account} from "./ERC6551Account.sol";
import {IERC6551Account}  from "../src/interfaces/IERC6551Account.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LoyaltyProgram is ERC1155, IERC1155Receiver, ReentrancyGuard {
  
  /* errors */
  error LoyaltyProgram__TransferDenied(); 
  error LoyaltyProgram__OnlyOwner(); 
  error LoyaltyProgram__InSufficientPoints(); 
  error LoyaltyProgram__LoyaltyCardNotRecognised(); 
  error LoyaltyProgram__LoyaltyTokenNotRecognised(); 
  error LoyaltyProgram__NotOwnerLoyaltyCard(); 
  error LoyaltyProgram__CardCanOnlyReceivePoints(); 
  error LoyaltyProgram__LoyaltyCardNotAvailable(); 
  error LoyaltyProgram__VendorLoyaltyCardCannotBeTransferred(); 

  /* State variables */
  uint256 public constant LOYALTY_POINTS = 0;
  uint256 public constant INITIAL_SUPPLY_POINTS = 1e25;

  address private s_owner; 
  mapping(address => uint256) private s_LoyaltyTokens; // 0 = false & 1 = true. 
  mapping(address => uint256) private s_LoyaltyCards; // 0 = false & 1 = true.
  // NB! I can get available tokens from loyaltyTokenAddress! 
  uint256 private s_loyaltyCardCounter;
  ERC6551Registry public s_erc6551Registry;
  ERC6551Account public s_erc6551Implementation;

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
      s_erc6551Implementation = new ERC6551Account(); 

      mintLoyaltyCards(23);
      mintLoyaltyPoints(INITIAL_SUPPLY_POINTS); 
  }

  receive() external payable {}

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

  function mintLoyaltyPoints(uint256 numberOfPoints) public onlyOwner {
    _mint(s_owner, LOYALTY_POINTS, numberOfPoints, "");
  }

  function transferLoyaltyCards(
    address payable tokenBoundAddress, 
    address from, 
    address to, 
    uint256 id, 
    uint256 value, 
    bytes memory data
  ) public returns (bytes memory result ) {
    bool success; 
    (success, result) = address(tokenBoundAddress).call(_encodeSafeTransferFrom(
      from, to, id, value, data));

    return result;  
  }

  function addLoyaltyTokenContract(address loyaltyToken) public onlyOwner {
    // later additional checks will be added here. 
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

  function redeemLoyaltyPoints(
    address loyaltyToken, 
    uint256 loyaltyPoints,
    uint256 loyaltyCardId
    ) external nonReentrant {
      address loyaltyCardAddress = getTokenBoundAddress(loyaltyCardId);

      // checks
      if (balanceOf(msg.sender, loyaltyCardId) != 0) {
        revert LoyaltyProgram__NotOwnerLoyaltyCard(); // is this necessary? or already covered by 6551account? 
      }
      if (loyaltyPoints < balanceOf(loyaltyCardAddress, 0)) {
        revert LoyaltyProgram__InSufficientPoints(); 
      }
      if (s_LoyaltyTokens[loyaltyToken] == 0) {
        revert LoyaltyProgram__LoyaltyTokenNotRecognised(); 
      }
      
      // requirements check = external. 
      (bool success) = LoyaltyToken(loyaltyToken).requirementsLoyaltyTokenMet(loyaltyCardAddress, loyaltyPoints); 
      // updating balances / interaction 
      if (success) {
        safeTransferFrom(
          loyaltyCardAddress, 
          address(0), // loyalty points are send to burner address.  
          0, 
          loyaltyPoints, 
          ""
          ); 
        }

      // claiming Nft / external. 
      uint256 tokenId = LoyaltyToken(loyaltyToken).claimNft(loyaltyCardAddress); 
      emit ClaimedLoyaltyToken(loyaltyToken, tokenId, loyaltyCardAddress); 
  }

  function RedeemLoyaltyToken(
    address loyaltyToken, 
    uint256 loyaltyTokenId, 
    uint256 loyaltyCard
    ) external nonReentrant {
      if (balanceOf(msg.sender, loyaltyCard) != 0) {
        revert LoyaltyProgram__NotOwnerLoyaltyCard(); 
      }
      address loyaltyCardAddress = getTokenBoundAddress(loyaltyCard);
      LoyaltyToken(loyaltyToken).redeemNft(loyaltyCardAddress, loyaltyTokenId); 

      emit RedeemedLoyaltyToken(loyaltyToken, loyaltyTokenId, loyaltyCardAddress); 
  }

  function getTokenBoundAddress (uint256 _loyaltyCardId) public view returns (address tokenBoundAccount) { 
    tokenBoundAccount = s_erc6551Registry.account(
            address(s_erc6551Implementation),
            block.chainid,
            address(this),
            _loyaltyCardId,
            3947539732098357
        );

    return tokenBoundAccount; 
  }



// I should try an delete these ones - and see what happens.. 
  function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
      return this.onERC1155BatchReceived.selector;
  }



  /* internal */  
  /** 
   * @dev Loyalty points and tokens can only transferred to
   * - other loyalty cards. 
   * - loyalty token contracts. 
   * - address(0) - to burn.
   * - owner of this contracts, s_owner (used ofr minting points).
   * LoyaltyCards can be transferred anywhere. 
   * @dev All other params remain unchanged. 
  */ 
  function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal override virtual {
    for (uint256 i = 0; i < ids.length; ++i) {
      if (ids[i] == LOYALTY_POINTS) {
        if (
          s_LoyaltyCards[to] == 0 && // points cann be transferred to loyalty cards
          s_LoyaltyTokens[to] == 0 && // points can be transferred to loyalty Token Contracts 
          to != address(0) && // points can be transferred to address(0) = burn address
          to != s_owner // points can be transferred to owner (address that minted points are transferred to)
          ) {
            // All other addresses are no-go.
            revert LoyaltyProgram__TransferDenied(); 
        }
      } 
    }
    super._update(from, to, ids, values); 
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

  function _encodeSafeTransferFrom(
    address from, 
    address to, 
    uint256 id, 
    uint256 value, 
    bytes memory data
    ) internal returns (bytes memory) { // this should probabl;y be internal private 
      return abi.encodeCall(
        IERC1155.safeTransferFrom, (from, to, id, value, data)
        ); 
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

  function getBalanceLoyaltyCard(uint256 loyaltyCardId) external view returns (uint256) {
    address loyaltyCardAddress = getTokenBoundAddress(loyaltyCardId);
    return balanceOf(loyaltyCardAddress, 0); 
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
