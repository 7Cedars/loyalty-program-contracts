// When reviewing this code, check: https://github.com/transmissions11/solcurity
// see also: https://github.com/nascentxyz/simple-security-toolkit
// Covering gas for user logic was taken from https://learnweb3.io/lessons/using-metatransaction-to-pay-for-your-users-gas 
// See for setup example in foundry book (does not use OpenZeppelin libs): https://book.getfoundry.sh/tutorials/testing-eip712 
// see for a concrete implementation with front end https://medium.com/coinmonks/eip-712-example-d5877a1600bd 
// see: https://solidity-by-example.org/structs/ re how to create structs

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC6551Account} from "../src/interfaces/IERC6551Account.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ILoyaltyGift} from "./interfaces/ILoyaltyGift.sol";

import {ERC165Checker} from  "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC6551Registry} from "./mocks/ERC6551Registry.sol";
import {ERC6551BespokeAccount} from "./mocks/ERC6551BespokeAccount.sol";
import {LoyaltyGift} from "./mocks/LoyaltyGift.sol";

/**
 * @title LoyaltyProgram
 * @author Seven Cedars
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
    error LoyaltyProgram__TransferDeniedX();
    error LoyaltyProgram__OnlyOwner();
    error LoyaltyProgram__InSufficientPoints();
    error LoyaltyProgram__LoyaltyCardNotRecognised();
    error LoyaltyProgram__RequestAlreadyExecuted();
    error LoyaltyProgram__RequestInvalid(); 
    error LoyaltyProgram__LoyaltyGiftNotRecognised();
    error LoyaltyProgram__LoyaltyGiftNotClaimable(); 
    error LoyaltyProgram__DoesNotOwnLoyaltyCard(); 
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
    uint256 public constant LOYALTY_POINTS_ID = 0;
    uint256 private constant SALT_TOKEN_BASED_ACCOUNT = 3947539732098357; 

    // EIP712 domain separator
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract; 
    }

    // RequestGift message struct
    struct RequestGift {
        address from;
        address to;
        string gift;
        string cost;
        uint256 nonce;
    }

    // Redeem token message struct
    struct RedeemVoucher {
        address from;
        address to;
        string voucher;
        uint256 nonce;
    }

    address private s_owner;
    bytes32 private DOMAIN_SEPARATOR;
    
    mapping(bytes32 => uint256 executed) requestExecuted; // 0 = false & 1 = true.
    mapping(address loyaltyCard => uint256 nonce) private s_nonceLoyaltyCard;
    mapping(address loyaltyCardAddress => uint256 exists) private s_LoyaltyCards; // 0 = false & 1 = true.
    mapping(address loyaltyGiftsAddress => mapping (uint256 loyaltyGiftId => uint256 exists)) private s_LoyaltyGiftsClaimable; // 0 = false & 1 = true.
    mapping(address loyaltyGiftsAddress => mapping (uint256 loyaltyGiftId => uint256 exists)) private s_LoyaltyGiftsRedeemable; // 0 = false & 1 = true.
    uint256 private s_loyaltyCardCounter;
    ERC6551Registry public s_erc6551Registry; 
    ERC6551BespokeAccount public s_erc6551Implementation;

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
     * @dev minting ERC6551 loyaltyCards: NFTs linked to token bound account.  
     * @param uri the uri linked to the loyalty program. See for example layout of this Uri the LoyaltyPrograms folder. 
     * 
     * @notice s_owner is now set as msg-sender and cannot be changed later on.
     * @notice input for erc6551Registry and erc6551Implementation addresses. This is to allow for easy testing (addresses on test networks for registry and implementation contracts might differ from standard addresses.)
     * @notice setup of  ERC-712 DOMAIN_SEPARATOR
     * 
     * emits a DeployedLoyaltyProgram event.  
     */
    constructor(string memory uri, address erc6551Registry, address payable erc6551Implementation) ERC1155(uri) {
        s_owner = msg.sender;
        s_loyaltyCardCounter = 0;
        s_erc6551Registry = ERC6551Registry(erc6551Registry); 
        s_erc6551Implementation = ERC6551BespokeAccount(erc6551Implementation);
        
        DOMAIN_SEPARATOR = hashDomain(EIP712Domain({
            name: "Loyalty Program",
            version: "1",
            chainId: block.chainid,
            // Following line fails in testing.. 
            verifyingContract: address(this) 
        }));
        
        // emit DeployedLoyaltyProgram(address(this) );
        emit DeployedLoyaltyProgram(msg.sender);
    }

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

        /** @dev note that I log these addresses as TBAs BEFORE they have actually been minted.  */
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
        _mint(s_owner, LOYALTY_POINTS_ID, numberOfPoints, "");
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

    function addLoyaltyGift(address loyaltyGiftAddress, uint256 loyaltyGiftId) public onlyOwner {
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
        s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] = 0;
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
     * - emits transferSingle event when one token is minted. 
     * - emits transferBatch when more tokens are minted?  
     */
    function mintLoyaltyVouchers(address loyaltyGiftAddress, uint256[] memory loyaltyGiftIds, uint256[] memory numberOfTokens) public onlyOwner nonReentrant {
        LoyaltyGift(loyaltyGiftAddress).mintLoyaltyVouchers(loyaltyGiftIds, numberOfTokens);
    }

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
        string memory _gift,
        string memory _cost, 
        address loyaltyGiftsAddress, 
        uint256 loyaltyGiftId, 
        uint256 loyaltyCardId,
        address customerAddress, 
        uint256 loyaltyPoints,  
        bytes memory signature
        )
        external nonReentrant onlyOwner 
        {   
            address loyaltyCardAddress = getTokenBoundAddress(loyaltyCardId); 
            
            RequestGift memory message; 
            message.from = loyaltyCardAddress; 
            message.to = address(this);  
            message.gift = _gift;  
            message.cost = _cost; 
            message.nonce = 0; // s_nonceLoyaltyCard[loyaltyCardAddress]; 
            bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message)); 

            // Check that this signer is loyaltyCard from which points are send. 
            address signer = digest.recover(signature);
            
            if(signer != customerAddress) {  //customerAddress
                revert LoyaltyProgram__RequestInvalid(); 
            }

            // check if signer owns loyaltyCard 
            if (balanceOf(signer, loyaltyCardId) == 0) {
                revert LoyaltyProgram__DoesNotOwnLoyaltyCard(); 
            }

            // Check that this signature hasn't already been executed
            if(requestExecuted[digest] == 1) {
                revert LoyaltyProgram__RequestAlreadyExecuted(); 
            }
 
            // check if Loyalty Token is active to be claimed. 
            if (s_LoyaltyGiftsClaimable[loyaltyGiftsAddress][loyaltyGiftId] == 0) {
                revert LoyaltyProgram__LoyaltyGiftNotClaimable();
            }

            // if all checks passed: 
            // 1) set executed to true..  
            requestExecuted[digest] = 1;
            // 2) add 1 to nonce 
            s_nonceLoyaltyCard[loyaltyCardAddress] = s_nonceLoyaltyCard[loyaltyCardAddress] + 1; 
            // 3) retrieve loyalty points from customer 
            _safeTransferFrom(loyaltyCardAddress, s_owner, 0, loyaltyPoints, ""); 
            // and 3) transfer token. 
            LoyaltyGift(loyaltyGiftsAddress).issueLoyaltyGift(loyaltyCardAddress, loyaltyGiftId, loyaltyPoints);      
    }

    function redeemLoyaltyVoucher(
        string memory _voucher,
        address loyaltyGift, 
        uint256 loyaltyGiftId, 
        uint256 loyaltyCardId,
        address customerAddress, 
        bytes memory signature
        ) 
        external nonReentrant onlyOwner 
        {
            address loyaltyCardAddress = getTokenBoundAddress(loyaltyCardId); 

            RedeemVoucher memory message; 
            message.from = loyaltyCardAddress; 
            message.to = address(this);  
            message.voucher = _voucher;  
            message.nonce = s_nonceLoyaltyCard[loyaltyCardAddress]; 
            bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRedeemVoucher(message)); 

            // Check that this signer is loyaltyCard from which points are send. 
            address signer = digest.recover(signature);
            if(signer != customerAddress) {
                revert LoyaltyProgram__RequestInvalid(); 
            } 

            // check if signer owns loyaltyCard 
            if (balanceOf(signer, loyaltyCardId) == 0) {
                revert LoyaltyProgram__DoesNotOwnLoyaltyCard(); 
            }

            // Check that this signature hasn't already been executed
            if(requestExecuted[digest] == 1) {
                revert LoyaltyProgram__RequestAlreadyExecuted(); 
            }
            
            // check if loyaltyGift is redeemable. 
            if (s_LoyaltyGiftsRedeemable[loyaltyGift][loyaltyGiftId] == 0) {
                revert LoyaltyProgram__LoyaltyTokensNotRedeemable();
            }

            // if check pass:  
            // 1) set executed to true..  
            requestExecuted[digest] = 1;
            s_nonceLoyaltyCard[loyaltyCardAddress] = s_nonceLoyaltyCard[loyaltyCardAddress] + 1; 

            // 2) redeem loyalty token (emits a transferSingle event.)
            LoyaltyGift(loyaltyGift).reclaimLoyaltyVoucher(loyaltyCardAddress, loyaltyGiftId);
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

    function hashDomain(EIP712Domain memory domain) private pure returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(domain.name)),
            keccak256(bytes(domain.version)),
            domain.chainId,
            domain.verifyingContract
        ));
    }

    function hashRequestGift(RequestGift memory message) private pure returns (bytes32) {
        return keccak256(abi.encode(
            // keccak256(bytes("RequestGift(uint256 nonce)")),
            keccak256(bytes("RequestGift(address from,address to,string gift,string cost,uint256 nonce)")),
            message.from,
            message.to, 
            keccak256(bytes(message.gift)), 
            keccak256(bytes(message.cost)),
            message.nonce
        ));
    }

    function hashRedeemVoucher(RedeemVoucher memory message) private pure returns (bytes32) {
        return keccak256(abi.encode(
            keccak256(bytes("RedeemVoucher(address from,address to,string voucher,uint256 nonce)")),
            message.from,
            message.to, 
            keccak256(bytes(message.voucher)),
            message.nonce
        ));
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
            if (ids[i] == LOYALTY_POINTS_ID) {
                if (                             // if ...  
                    s_LoyaltyCards[to] == 0 &&   // points are not transferred to loyalty cards...
                    to != s_owner // ...or to owner... 
                ) {
                    // ...revert
                    revert LoyaltyProgram__TransferDenied();
                }
            } 
            if (ids[i] != LOYALTY_POINTS_ID) {
                 if (s_LoyaltyCards[to] == 1) {
                    revert LoyaltyProgram__TransferDeniedX();
                 } 
            }
        }
        super._update(from, to, ids, values);
    }

    function _createTokenBoundAccount(uint256 _loyaltyCardId) internal returns (address tokenBoundAccount) {
        tokenBoundAccount = s_erc6551Registry.createAccount(
            address(s_erc6551Implementation), block.chainid, address(this), _loyaltyCardId, SALT_TOKEN_BASED_ACCOUNT, ""
        );

        return tokenBoundAccount;
    }

    /* Getter functions */
    function getOwner() external view returns (address) {
        return s_owner;
    }
    
    function getTokenBoundAddress(uint256 _loyaltyCardId) public view returns (address tokenBoundAccount) {
        tokenBoundAccount = s_erc6551Registry.account(
            address(s_erc6551Implementation), block.chainid, address(this), _loyaltyCardId, SALT_TOKEN_BASED_ACCOUNT
        );
        return tokenBoundAccount;
    }

    function getLoyaltyGiftsIsClaimable(address loyaltyGiftAddress, uint256 loyaltyGiftId) external view returns (uint256) {
        return s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId];
    }

    function getLoyaltyGiftsIsRedeemable(address loyaltyGiftAddress, uint256 loyaltyGiftId) external view returns (uint256) {
        return s_LoyaltyGiftsRedeemable[loyaltyGiftAddress][loyaltyGiftId];
    }

    function getNumberLoyaltyCardsMinted() external view returns (uint256) {
        return s_loyaltyCardCounter;
    }

    function getBalanceLoyaltyCard(address loyaltyCardAddress) external view returns (uint256) {
        return balanceOf(loyaltyCardAddress, 0);
    }

    function getNonceLoyaltyCard(address loyaltyCardAddress) external view returns (uint256) {
        // should build in check here later. Only owner of card + loyalty program can request nonce. 
        return s_nonceLoyaltyCard[loyaltyCardAddress];
    }
}

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
