// When reviewing this code, check: https://github.com/transmissions11/solcurity
// see also: https://github.com/nascentxyz/simple-security-toolkit
// Covering gas for user logic was taken from https://learnweb3.io/lessons/using-metatransaction-to-pay-for-your-users-gas 
// See for setup example in foundry book (does not use OpenZeppelin libs): https://book.getfoundry.sh/tutorials/testing-eip712 

// Structure contract //
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC165Checker} from  "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {LoyaltyGift} from "./LoyaltyGift.sol";
import {ILoyaltyGift} from "./interfaces/ILoyaltyGift.sol";
import {ERC6551Registry} from "./ERC6551Registry.sol";
import {ERC6551Account} from "./ERC6551Account.sol";
import {IERC6551Account} from "../src/interfaces/IERC6551Account.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title LoyaltyProgram
 * @author 7 Cedars
 * @notice Customer Loyalty program: issues loyalty cards (a non-fungible token) to customers, that enables
 * - collection of loyalty points (a fungible token) as gifted by vendor.
 * - redeeming loyalty points to claim loyalty tokens (a semi-fungible token) that represent vendor gifts, events, etc
 * - redeeming loyalty tokens at vendor to receive actual gift, event, etc.
 * - points and tokens are kept on loyalty cards - that are freely transferrable.
 *
 * @notice This contract interacts with loyalty token contracts that define the requirement logics
 * for redeemin points (and any other type of data) for loyalty token.
 * 
 * @notice Loyalty Points are minted at loyalty Program by the owner. 
 * Loyalty Tokens are minted at the Loyalty Tokens by the Loyalty Program. 
 * e.g. points and tokens are held by different contracts.  
 * 
 * @notice The contract builds on the ERC1155 and ERC6551 standards, and is meant as a showcase
 * of using both fungible, semi-fungible and non-fungible tokens as a utility, rather than
 * store/exchange of value.
 */
contract LoyaltyProgram is ERC1155, IERC1155Receiver, ReentrancyGuard {
    /* errors */
    error LoyaltyProgram__TransferDenied();
    error LoyaltyProgram__OnlyOwner();
    error LoyaltyProgram__InSufficientPoints();
    error LoyaltyProgram__LoyaltyCardNotRecognised();
    error LoyaltyProgram__RequestAlreadyExecuted();
    error LoyaltyProgram__RequestNotFromLoyaltyCard(address signer); 
    error LoyaltyProgram__LoyaltyGiftNotRecognised();
    error LoyaltyProgram__LoyaltyGiftNotClaimable(); 
    error LoyaltyProgram__LoyaltyTokensNotRedeemable();
    error LoyaltyProgram__CardCanOnlyReceivePoints();
    error LoyaltyProgram__LoyaltyCardNotAvailable();
    error LoyaltyProgram__VendorLoyaltyCardCannotBeTransferred();
    error LoyaltyProgram__InSufficientPointsOnCard();
    error LoyaltyProgram__LoyaltyGiftNotOnCard();
    error LoyaltyProgram__IncorrectContractInterface(address loyaltyGift);

    /* Type declarations */
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /* State variables */
    uint256 public constant LOYALTY_POINTS = 0;

    address private s_owner;
    mapping(bytes32 => uint256 executed) requestExecuted; // 0 = false & 1 = true.
    mapping(address loyaltyCard => uint256 nonce) private s_nonceLoyaltyCard;
    mapping(address loyaltyCardAddress => uint256 exists) private s_LoyaltyCards; // 0 = false & 1 = true.
    mapping(address loyaltyGiftsAddress => mapping (uint256 loyaltyGiftId => uint256 exists)) private s_LoyaltyGiftsClaimable; // 0 = false & 1 = true.
    mapping(address loyaltyGiftsAddress => mapping (uint256 loyaltyGiftId => uint256 exists)) private s_LoyaltyGiftsRedeemable; // 0 = false & 1 = true.
    uint256 private s_loyaltyCardCounter;
    ERC6551Registry public s_erc6551Registry;
    ERC6551Account public s_erc6551Implementation;

    /* Events */
    event DeployedLoyaltyProgram(address indexed owner);
    event AddedLoyaltyGift(address indexed loyaltyGift, uint256 loyaltyGiftId);
    event RemovedLoyaltyGiftClaimable(address indexed loyaltyGift, uint256 loyaltyGiftId);
    event RemovedLoyaltyGiftRedeemable(address indexed loyaltyGift, uint256 loyaltyGiftId);

    /* Modifiers */
    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert LoyaltyProgram__OnlyOwner();
        }
        _;
    }

    /**
     * Emits a DeployedLoyaltyProgram event. 
     */
    constructor(string memory uri) ERC1155(uri) {
        // still have to check if this indeed gives out same uri for each NFT minted. Yep - it does. 
        s_owner = msg.sender;
        s_loyaltyCardCounter = 0;
        s_erc6551Registry = new ERC6551Registry();
        s_erc6551Implementation = new ERC6551Account();

        emit DeployedLoyaltyProgram(msg.sender);
    }

    receive() external payable {}

    /**
     * @dev minting ERC6551 loyaltyCards: NFTs linked to token bound account.  
     * @param numberOfLoyaltyCards amount of loyaltycards to be minted.
     * 
     * @notice only owner of program can mint loyalty cards. 
     * @notice no limit to the amount of cards to mint. 
     * @notice each address of Token Bound Account (TBA) is stored in s_LoyaltyCards. 
     * 
     * - emits a transferBatch event.  
     */
    function mintLoyaltyCards(uint256 numberOfLoyaltyCards) public onlyOwner {
        uint256[] memory loyaltyCardIds = new uint256[](numberOfLoyaltyCards);
        uint256[] memory mintNfts = new uint256[](numberOfLoyaltyCards);
        uint256 counter = s_loyaltyCardCounter;

        /** @dev note that I log these addresses internally BEFORE they have actually been minted.  */
        for (uint256 i; i < numberOfLoyaltyCards; i++) {
            // i starts at 0.... right? TEST!
            counter = counter + 1;
            loyaltyCardIds[i] = counter;
            mintNfts[i] = 1;
            address loyaltyCardAddress = _createTokenBoundAccount(counter);
            s_LoyaltyCards[loyaltyCardAddress] = 1;
        }

        _mintBatch(msg.sender, loyaltyCardIds, mintNfts, "");
        s_loyaltyCardCounter = s_loyaltyCardCounter + numberOfLoyaltyCards;
    }

    /**
     * @dev minting ERC1155 (fungible token) Loyalty Points. 
     * @param numberOfPoints number of loyalty points to be minted. 
     * 
     * @notice only owner can mint loyalty points. 
     * @notice no limit to the amount of points to mint. 
     * 
     * - emits transferSingle event. 
     */
    function mintLoyaltyPoints(uint256 numberOfPoints) public onlyOwner {
        _mint(s_owner, LOYALTY_POINTS, numberOfPoints, "");
    }

    /** 
     * @dev whitelisting contracts that customers can use to redeem loyalty points and loyalty tokens. 
     * If contract does not have LoyaltyGift interface, function reverts.
     * The interface for this has not been written yet. 
     * 
     * ADD PARAMS LATER
     * @notice only owner can whitelist contracts.  
     * @notice at the moment it lacks interface test. To do. 
     * 
     * - emits a AddedLoyaltyGift event
     */

    function addLoyaltyGift(address payable loyaltyGiftAddress, uint256 loyaltyGiftId) public onlyOwner {
        // CAUSES many reverts :D Needs bug fixing... 
        // bytes4 interfaceId = type(ILoyaltyGift).interfaceId; 
        // if (ERC165Checker.supportsERC165InterfaceUnchecked(loyaltyGift, interfaceId) == false) {
        //     revert LoyaltyProgram__IncorrectContractInterface(loyaltyGift);
        // }
        s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] = 1;
        s_LoyaltyGiftsRedeemable[loyaltyGiftAddress][loyaltyGiftId] = 1;
        emit AddedLoyaltyGift(loyaltyGiftAddress, loyaltyGiftId);
    }

    /**
     * @dev remove a loyalty contract from whitelist to claim loyalty gifts. 
     * ADD PARAMS LATER loyaltyGift address of loyaltyGift to be removed from whitelist. 
     * 
     * @notice after calling this function customers can still redeem tokens they
     * received as gift, event, etc. 
     * @notice only owner can remove contracts from whitelist. 
     * 
     * - emits an RemovedLoyaltyGiftClaimable event. 
     */
    function removeLoyaltyGiftClaimable(address loyaltyGiftAddress, uint256 loyaltyGiftId) public onlyOwner {
        if (s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] == 0) {
            revert LoyaltyProgram__LoyaltyGiftNotRecognised();
        }
        s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] = 0;
        emit RemovedLoyaltyGiftClaimable(loyaltyGiftAddress, loyaltyGiftId);
    }

    /**
     * @dev remove a loyalty contract from whitelist for its tokens to be redeemable. 
     * i.e. After calling this function, customers will not be able to 'redeem' tokens associated with this LoyaltyGift contract.
     * This is an extreme measure (people will be stuck with worthless Tokens) and should only be used on extreme cases (malfunction, hack, etc). 
     * ADD PARAMS LATER loyaltyGift address of loyaltyGift to be removed from whitelist. 
     * 
     * @notice after calling this function customers cannot redeem tokens.  
     * @notice it also removes token from claimable whitelist, avoiding scenario where token can be claimed but not redeemed. 
     * @notice only owner can remove contracts from whitelist. 
     * 
     * - emits an RemovedLoyaltyGiftRedeemable event. 
     */
    function removeLoyaltyGiftRedeemable(address loyaltyGiftAddress, uint256 loyaltyGiftId) public onlyOwner {
        if (s_LoyaltyGiftsRedeemable[loyaltyGiftAddress][loyaltyGiftId] == 0) {
            revert LoyaltyProgram__LoyaltyGiftNotRecognised();
        }
        s_LoyaltyGiftsRedeemable[loyaltyGiftAddress][loyaltyGiftId] = 0;

        emit RemovedLoyaltyGiftRedeemable(loyaltyGiftAddress, loyaltyGiftId);
    }

    /** 
     * @dev mint loyaltyGifts at external loyaltyGift contract. 
     * @param loyaltyGiftAddress address of loyalty token contract. 
     * @param numberOfTokens amount of tokens to be minted. 
     * 
     * @notice the limit of loyalty tokens that customers can be gifted is limited by the amount of tokens minted by the owner of loyalty program. 
     * @notice only owner can remove contracts from whitelist. 
     * @notice added nonReentrant guard. 
     * 
     * - emits transferBatch event 
     */
    function mintLoyaltyTokens(address payable loyaltyGiftAddress, uint256[] memory loyaltyGiftIds, uint256[] memory numberOfTokens) public onlyOwner nonReentrant {
        LoyaltyGift(loyaltyGiftAddress).mintLoyaltyTokens(loyaltyGiftIds, numberOfTokens);
    }


    /////////////////////////////////////////////////////////////////////////////////////
    /// THIS FUNCTION NEEDS TO BE REFACTORED: GAS SHOULD BE COVERED BY LOYALTYPROGRAM /// 
    /////////////////////////////////////////////////////////////////////////////////////
    /** 
     * @dev redeem loyaltyPoints for loyaltyGift by a Token Bound Account (the loyalty card). 
     * The loyalty card calls the requirement function of external loyaltyGift contract. 
     * ADD PARAMS LATER. 
     *
     * 
     * @notice only one token can be claimed per call. 
     * @notice any loyaltyCard minted through loyalty program can redeem loyalty points. 
     * @notice CHECK add nonReentrant guard as CEI structure can not be 100% followed?  
     * @notice if customer does not own TBA / loyalty card it will revert at ERC6551 account.  
     * 
     * - emits a TransferSingle event 
     */
    function claimLoyaltyGift(
        address loyaltyGiftsAddress, 
        uint256 loyaltyGiftId, 
        address loyaltyCardAddress,
        address customerAddress, 
        uint256 loyaltyPoints, 
        bytes memory signature)
        external
        nonReentrant
        onlyOwner
    {
        bytes32 messageHash = keccak256(abi.encodePacked(
            loyaltyGiftsAddress, 
            loyaltyGiftId, 
            loyaltyCardAddress, 
            customerAddress,
            loyaltyPoints, 
            s_nonceLoyaltyCard[loyaltyCardAddress]
            )).toEthSignedMessageHash();
        
        // Check that this signature hasn't already been executed
        if(requestExecuted[messageHash] == 1) {
            revert LoyaltyProgram__RequestAlreadyExecuted(); 
        }
        
        // Check that this signer is loyaltyCard from which points are send. 
        address signer = messageHash.recover(signature);
        if(signer != customerAddress) {
            revert  LoyaltyProgram__RequestNotFromLoyaltyCard(signer); 
        }

        // check if Loyalty Token is active to be claimed. 
        if (s_LoyaltyGiftsClaimable[loyaltyGiftsAddress][loyaltyGiftId] == 0) {
            revert LoyaltyProgram__LoyaltyGiftNotClaimable();
        }

        // if all checks passed: 
        // 1) set executed to true..  
        requestExecuted[messageHash] = 1;
        s_nonceLoyaltyCard[loyaltyCardAddress] = s_nonceLoyaltyCard[loyaltyCardAddress] + 1; 
        
        // and 3) claim token. 
        LoyaltyGift(payable(loyaltyGiftsAddress)).claimLoyaltyGift(loyaltyCardAddress, loyaltyGiftId, loyaltyPoints);      
    }

    function redeemLoyaltyToken(
        address loyaltyGift, 
        uint256 loyaltyGiftId, 
        address loyaltyCardAddress,
        address customerAddress, 
        bytes memory signature
        )
        external
        nonReentrant
        onlyOwner
    {
        // note: nonce passed into messageHAsh here. 
        bytes32 messageHash = keccak256(abi.encodePacked(
            loyaltyGift, 
            loyaltyGiftId,
            loyaltyCardAddress,
            customerAddress,
            s_nonceLoyaltyCard[loyaltyCardAddress]
            )).toEthSignedMessageHash();

            
        // Check that this signature hasn't already been executed
        // if(requestExecuted[messageHash] == 1) {
        //     revert LoyaltyProgram__RequestAlreadyExecuted(); 
        // }
        
        // Check that this signer is loyaltyCard from which points are send. 
        // address signer = messageHash.recover(signature);
        // if(signer != customerAddress) {
        //     revert  LoyaltyProgram__RequestNotFromLoyaltyCard(signer); 
        // } 

        // check if loyaltyGift is redeemable. 
        // if (s_LoyaltyGiftsRedeemable[loyaltyGift] == 0) {
        //     revert LoyaltyProgram__LoyaltyTokensNotRedeemable();
        // }

        // if check pass:  
        // 1) set executed to true..  
        requestExecuted[messageHash] = 1;
        s_nonceLoyaltyCard[loyaltyCardAddress] = s_nonceLoyaltyCard[loyaltyCardAddress] + 1;

        // 2) redeem loyalty token (emits a transferSingle event.)
        LoyaltyGift(payable(loyaltyGift)).redeemLoyaltyToken(loyaltyCardAddress, loyaltyGiftId);

    }

    // Without these transactions are declined. 
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    /* internal */
    /**
     * @dev Loyalty points can only transferred to
     * - loyalty cards.
     * - owner of this contracts, s_owner - when paying for gifts in tokens.
     * LoyaltyCards cannot be transferred to other loyaltyCards. For the rest they can be transferred anywhere. 
     * @dev All other params remain unchanged.
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override
    {
        for (uint256 i; i < ids.length; ++i) {
            if (ids[i] == LOYALTY_POINTS) {
                if (                             // if ...  
                    s_LoyaltyCards[to] == 0 &&   // points are not transferred to loyalty cards...
                    to != s_owner // ...or to owner... 
                ) {
                    // ...revert
                    revert LoyaltyProgram__TransferDenied();
                }
            } 
            if (ids[i] != LOYALTY_POINTS) {
                 if (s_LoyaltyCards[to] == 1) {
                    revert LoyaltyProgram__TransferDenied();
                 } 
            }
        }
        super._update(from, to, ids, values);
    }

    function _createTokenBoundAccount(uint256 _loyaltyCardId) internal returns (address tokenBoundAccount) {
        tokenBoundAccount = s_erc6551Registry.createAccount(
            address(s_erc6551Implementation), block.chainid, address(this), _loyaltyCardId, 3947539732098357, ""
        );

        return tokenBoundAccount;
    }

    /* Getter functions */
    function getOwner() external view returns (address) {
        return s_owner;
    }
    
    function getTokenBoundAddress(uint256 _loyaltyCardId) public view returns (address tokenBoundAccount) {
        tokenBoundAccount = s_erc6551Registry.account(
            address(s_erc6551Implementation), block.chainid, address(this), _loyaltyCardId, 3947539732098357
        );
        return tokenBoundAccount;
    }

    function getLoyaltyGiftsIsClaimable(address loyaltyGiftAddress, uint256 loyaltyGiftId) external view returns (uint256) {
        return s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId];
    }

    function getNumberLoyaltyCardsMinted() external view returns (uint256) {
        return s_loyaltyCardCounter;
    }

    function getBalanceLoyaltyCard(address loyaltyCardAddress) external view returns (uint256) {
        return balanceOf(loyaltyCardAddress, 0);
    }

    function getNonceLoyaltyCard() external view returns (uint256) {
        if (s_LoyaltyCards[msg.sender] == 0) {
            revert LoyaltyProgram__LoyaltyCardNotRecognised(); 
        }
        return s_nonceLoyaltyCard[msg.sender];
    }
}
