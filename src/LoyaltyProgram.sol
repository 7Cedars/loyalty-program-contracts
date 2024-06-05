/**
 * NB: THIS CONTRACT HAS NOT BEEN AUDITED. TESTING IS INCOMPLETE. DO NOT DEPLOY ON ANYTHING ELSE THAN A TEST CHAIN 
 * 
 * @title Loyalty Program 
 * @author Seven Cedars, based on OpenZeppelin's ERC-1155 implementation.
 * @notice TL;DR The Loyalty protocol provides a modular, composable and gas efficient framework for blockchain based customer engagement programs.
 * 
 * */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ILoyaltyGift} from "./interfaces/ILoyaltyGift.sol";
import {ILoyaltyProgram} from "./interfaces/ILoyaltyProgram.sol";

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC6551Registry } from "@erc6551/ERC6551Registry.sol"; 
import {LoyaltyCard6551Account} from "./LoyaltyCard6551Account.sol";

contract LoyaltyProgram is ERC1155, IERC1155Receiver, ILoyaltyProgram { 
    /* errors */
    error LoyaltyProgram__OnlyOwner();
    error LoyaltyProgram__TransferDenied();
    error LoyaltyProgram__RequestAlreadyExecuted();
    error LoyaltyProgram__NotOwnerLoyaltyCard();
    error LoyaltyProgram__RequestInvalid();
    error LoyaltyProgram__LoyaltyGiftInvalid();
    error LoyaltyProgram__LoyaltyVoucherInvalid();
    error LoyaltyProgram__VoucherNotOwnedBySender();
    error LoyaltyProgram__VoucherTransferInvalid(); 
    error LoyaltyProgram__RequirementsGiftNotMet(); 
    error LoyaltyProgram__IncorrectInterface(address loyaltyGift);
    
    /* Events */
    event DeployedLoyaltyProgram(address indexed owner, string name, string indexed version);
    event AddedLoyaltyGift(address indexed loyaltyGift, uint256 indexed loyaltyGiftId);
    event RemovedLoyaltyGiftClaimable(address indexed loyaltyGift, uint256 indexed loyaltyGiftId);
    event RemovedLoyaltyGiftRedeemable(address indexed loyaltyGift, uint256 indexed loyaltyGiftId);

    /* Type declarations */
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    using ERC165Checker for address;

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

    // Redeem voucher message struct
    struct RedeemVoucher {
        address from;
        address to;
        string voucher;
        uint256 nonce;
    }

    /* State variables */
    uint256 public  constant LOYALTY_POINTS_ID = 0;
    bytes32 private constant SALT = 0x0000000000000000000000000000000000000000000000000000000007ceda52;
    address private constant ERC6551_REGISTRY = 0x000000006551c19487814612e58FE06813775758;

    // not set as constant as address can differ between chains and deployments. 
    address private immutable s_erc6551_account; 
    address private immutable s_owner;
    bytes32 private immutable DOMAIN_SEPARATOR;

    mapping(bytes => bool executed) private requestExecuted; 
    mapping(address loyaltyCard => uint256 nonce) private s_nonceLoyaltyCard; // NB: this data can be taken from blockchain. -- £sec = attack vector? 
    mapping(address loyaltyCardAddress => bool exists) private s_LoyaltyCards; 
    mapping(address loyaltyGiftAddress => mapping(uint256 loyaltyGiftId => bool exists)) private s_LoyaltyGiftsClaimable;
    mapping(address loyaltyGiftAddress => mapping(uint256 loyaltyGiftId => bool exists)) private s_LoyaltyVouchersRedeemable; 
    uint256 private s_loyaltyCardCounter;
    RequestGift claimMessage;
    RedeemVoucher redeemMessage; 

    /* Modifiers */
    // More advanced Role-Based Access Control (RBAC) can be implemented later. 
    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert LoyaltyProgram__OnlyOwner();
        }
        _;
    }

    /**
     * @notice constructor function for Loyalty program contract.
     * 
     * @param _uri the uri linked to the loyalty program.
     * @param _name the name of the Loyalty Program
     * @param _version the version of the Loyalty Program
     *
     * @dev s_owner is now set as msg-sender and cannot be changed later on. 
     * @dev also set up of ERC-712 DOMAIN_SEPARATOR. 
     *
     * emits a DeployedLoyaltyProgram event.
     */
    constructor(string memory _uri, string memory _name, string memory _version, address _erc6551_account) ERC1155(_uri) {
        s_owner = msg.sender;
        s_loyaltyCardCounter = 0;
        s_erc6551_account = _erc6551_account; 

        DOMAIN_SEPARATOR = hashDomain(
            EIP712Domain({
                name: _name,
                version: _version,
                chainId: block.chainid,
                verifyingContract: address(this)
            })
        );

        emit DeployedLoyaltyProgram(msg.sender, _name, _version);
    }

    /**
     * @notice mints loyaltyCards. Each is a non-fungible token (NFT) that is linked to a token bound account.
     * 
     * @param numberOfLoyaltyCards amount of loyaltycards to be minted.
     * 
     * @dev only owner of program can mint loyalty cards.
     * @dev first id of card is 1. (not 0, this id is reserved for loyalty points). 
     * @dev no limit to the amount of cards to mint - when too many are minted, gas limits kick in. 
     * @dev each address of Token Bound Account (TBA) is stored in s_LoyaltyCards.
     * @dev £security it should be (and I think is now) impossible to mint more than one loyaltyCard of the same Id. 
     * This is crucial as the LoyaltyCard6551Account contract does not have a check for this - due to this contract being ERC-1155 based (instead of ERC-721). 
     * if more than one card of the same id are minted, you _will_ have a loyalty Card with multiple owners. 
     *
     * @dev This function is a real gas guzzler. 
     * 
     * - emits a transferBatch event.
     */
    function mintLoyaltyCards(uint256 numberOfLoyaltyCards) public onlyOwner {
        uint256[] memory loyaltyCardIds = new uint256[](numberOfLoyaltyCards);
        uint256[] memory mintNfts = new uint256[](numberOfLoyaltyCards);
        uint256 counter = s_loyaltyCardCounter;

        /**
         * @dev £security question: note that I log these addresses as TBAs BEFORE they have actually been minted. Problem? 
         */
        for (uint256 i; i < numberOfLoyaltyCards; ) {
            counter = ++counter;
            loyaltyCardIds[i] = counter;
            mintNfts[i] = 1;
            address loyaltyCardAddress = _createTokenBoundAccount(counter);
            s_LoyaltyCards[loyaltyCardAddress] = true;
            unchecked { i++; } // gas optimisation. Check not necessary. 
        }

        _mintBatch(msg.sender, loyaltyCardIds, mintNfts, "");
        s_loyaltyCardCounter = s_loyaltyCardCounter + numberOfLoyaltyCards;
    }

    /**
     * @notice mints Loyalty Points: basic ERC1155 fungible styled token.
     * @param numberOfPoints number of loyalty points to be minted.
     *
     * @dev only owner can mint loyalty points.
     * @dev no limit to the amount of points to mint.
     * @dev the LOYALTY_POINTS_ID immutable sets id of points to 0.  
     *
     * - emits a transferSingle event.
     */
    function mintLoyaltyPoints(uint256 numberOfPoints) public onlyOwner {
        _mint(s_owner, LOYALTY_POINTS_ID, numberOfPoints, "");
    }

    /**
     * @notice whitelisting gift contracts and gift ids (these are contracts that provide requirements for redeeming loyalty points to gifts or vouchers).
     * A single gift contract can have mutliple gifts with each a seperate requirement.  
     *
     * @param loyaltyGiftAddress address of loyalty gift
     * @param loyaltyGiftId id of gift. 
     * 
     * @dev only owner can whitelist contracts. 
     * @dev gifts are added to two whitelists: for claiming gifts and for redeeming gift vouchers. 
     * This allows for a gift to be de-whitelisted by a vendor, without its vouchers becoming impossible to redeem.
     * It means that customers will not suddenly loose their vouchers when vendor decides to de-whitelist a gift. 
     *
     * - emits a AddedLoyaltyGift event
     */

    function addLoyaltyGift(address loyaltyGiftAddress, uint256 loyaltyGiftId) public onlyOwner {
        if (ERC165Checker.supportsInterface(loyaltyGiftAddress, type(ILoyaltyGift).interfaceId) == false) {
            revert LoyaltyProgram__IncorrectInterface(loyaltyGiftAddress);
        }
        s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] = true;
        s_LoyaltyVouchersRedeemable[loyaltyGiftAddress][loyaltyGiftId] = true;
        emit AddedLoyaltyGift(loyaltyGiftAddress, loyaltyGiftId);
    }

    /**
     * @notice removes a loyalty gift from claiming whitelist. After delisting, gift (or voucher) cannot be claimed by customer. 
     * 
     * @param loyaltyGiftAddress address of loyalty gift
     * @param loyaltyGiftId id of gift. 
     *
     * @dev after calling this function customers can still redeem vouchers they received as gift, event, etc.
     * @dev only owner can remove contracts from whitelist.
     *
     * - emits an RemovedLoyaltyGiftClaimable event.
     */
    function removeLoyaltyGiftClaimable(address loyaltyGiftAddress, uint256 loyaltyGiftId) public onlyOwner {
        if (s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] == false) {
            revert LoyaltyProgram__LoyaltyGiftInvalid();
        }
        s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] = false;
        emit RemovedLoyaltyGiftClaimable(loyaltyGiftAddress, loyaltyGiftId);
    }

    /**
     * @notice removes a loyalty voucher from whitelist to be redeemable. 
     * After delisting, customers will not be able to redeem vouchers associated with this Loyalty Gift.
     * 
     * @param loyaltyGiftAddress address of loyalty gift
     * @param loyaltyGiftId id of gift. 
     *
     * @dev Note that delisting means that customers' vouchers - without warning - become worthless. 
     * Calling this function is an extreme measure and should only be used on extreme cases (malfunction, hack, etc).
     * @dev it also removes gifts from claimable whitelist, avoiding scenario where voucher can be claimed but not redeemed.
     * @dev only owner can remove contracts from whitelist.
     * 
     * - emits an RemovedLoyaltyGiftRedeemable event.
     */
    function removeLoyaltyGiftRedeemable(address loyaltyGiftAddress, uint256 loyaltyGiftId) public onlyOwner {
        if (s_LoyaltyVouchersRedeemable[loyaltyGiftAddress][loyaltyGiftId] == false) {
            revert LoyaltyProgram__LoyaltyGiftInvalid();
        }
        s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] = false;
        s_LoyaltyVouchersRedeemable[loyaltyGiftAddress][loyaltyGiftId] = false;

        emit RemovedLoyaltyGiftRedeemable(loyaltyGiftAddress, loyaltyGiftId);
    }

    /**
     * @notice checks if requirements are met for loyaltyGift. 
     * 
     * @dev This function can be called by loyaltyCards (in contrast to function requirementsMet at Gift contract that can only be called by a LoyaltyProgram). 
     * 
     */
    function checkRequirementsLoyaltyGiftMet(
        address loyaltyCard, 
        address loyaltyGiftAddress,
        uint256 loyaltyGiftId 
    ) public returns (bool) {
        uint256 balanceSender = balanceOf(loyaltyCard, 0);  
        if (balanceSender == 0) {
            revert ("No loyalty points on card."); 
        }
        return ILoyaltyGift(loyaltyGiftAddress).requirementsLoyaltyGiftMet(loyaltyCard, loyaltyGiftId, balanceSender); 
    }

    /**
     * @notice mint loyaltyGifts at external loyaltyGift contract.
     * @param loyaltyGiftAddress address of loyalty gift contract.
     * @param loyaltyGiftIds id of loyaltyGift 
     * @param numberOfVouchers amount of vouchers to be minted.
     *
     * @dev the limit of loyalty vouchers that customers can be gifted is limited by the amount of vouchers minted by the owner of loyalty program.
     * @dev only owner can mint vouchers.
     *
     * - emits transferSingle event when one vouchers is minted.
     * - emits transferBatch when more vouchers are minted
     */
    function mintLoyaltyVouchers(
        address loyaltyGiftAddress,
        uint256[] memory loyaltyGiftIds,
        uint256[] memory numberOfVouchers
    ) public onlyOwner {
        ILoyaltyGift(loyaltyGiftAddress).mintLoyaltyVouchers(loyaltyGiftIds, numberOfVouchers);
    }

    /**
     * @notice transfer voucher between owner and/or among loyalty cards - bypassing any (requirement) checks.
     * @param from address from which voucher is send.  
     * @param to address that will receive voucher. 
     * @param loyaltyGiftAddress Address if Loyalty Gift contract. 
     * @param loyaltyGiftId Id of loyalty gift at Loyalty Gift contract. 
     *
     * @dev Either the to or from address have to be the owner of the contract. 
     * @dev safeTransferFrom at ILoyaltyGift bypasses the usual approval check because transfers need to be called via the LoyaltyProgram contract.  
     * Instead, checks of ownership are placed at the LoyaltyProgram contract, before calling safeTransferFrom at ILoyaltyGift / Loyalty Gift contract.  
     * 
     * - emits transferSingle event.
     */
    function transferLoyaltyVoucher(
        address from,
        address to,
        address loyaltyGiftAddress, 
        uint256 loyaltyGiftId
    ) public {
        if (from != s_owner && to != s_owner) {
            revert LoyaltyProgram__VoucherTransferInvalid();
        }

        if ( ILoyaltyGift(loyaltyGiftAddress).balanceOf(from, loyaltyGiftId) == 0 ) {
            revert LoyaltyProgram__VoucherNotOwnedBySender();
        }

        ILoyaltyGift(loyaltyGiftAddress).safeTransferFrom(from, to, loyaltyGiftId, 1, "");
    }

    /**
     * @notice redeems loyaltyPoints for loyalty Gift by calling external contract, using a signed message from customer.
     *
     * @param _gift description of gift. 
     * @param _cost description of cost (in points) of gift. e.g. "2500 points"
     * @param loyaltyGiftAddress address of loyalty gift to claim
     * @param loyaltyGiftId id of loyalty gift to claim 
     * @param loyaltyCardId id of loyalty card whose points are used to claim gift. 
     * @param customerAddress address of customer that makes the claim. 
     * @param loyaltyPoints amount of points sent to claim loyalty gift 
     * @param signature customer (EIP-712) signature used to sign message.  
     *
     * @dev only one voucher can be claimed per call.
     * @dev only loyaltyCards minted through this loyalty program can be used redeem loyalty points.
     * @dev £security removed nonReentrant guard as CEI (Check-Effect-Interaction) structure was followed and the function is onlyOwner. This is correct - right? 
     * @dev if customer does not own TBA / loyalty card it will revert at ERC6551 account.
     *
     * - emits a TransferSingle event
     */
    function claimLoyaltyGift(
        string memory _gift,
        string memory _cost,
        address loyaltyGiftAddress,
        uint256 loyaltyGiftId,
        uint256 loyaltyCardId,
        address customerAddress,
        uint256 loyaltyPoints,
        bytes memory signature
    ) external onlyOwner { // £security. nonRentrant not necessary here. - OnlyOwner function. 
        address loyaltyCardAddress = getTokenBoundAddress(loyaltyCardId);

        // filling up RequestGift struct with provided data. 
        claimMessage.from = loyaltyCardAddress;
        claimMessage.to = address(this);
        claimMessage.gift = _gift;
        claimMessage.cost = _cost;
        claimMessage.nonce = s_nonceLoyaltyCard[loyaltyCardAddress];
        
        // creating digest. 
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(claimMessage));

        // using this digest and signature to recover customer address 
        address signer = digest.recover(signature);

        // Checks. 
        // Check that this signature hasn't already been executed
        if (requestExecuted[signature] == true) {
            revert LoyaltyProgram__RequestAlreadyExecuted();
        }

        // Checks if signer equals customer address
        if (signer != customerAddress) {
            revert LoyaltyProgram__RequestInvalid();
        }

        // check if signer owns loyaltyCard
        if (balanceOf(signer, loyaltyCardId) == 0) {
            revert LoyaltyProgram__NotOwnerLoyaltyCard();
        }

        // check if Loyalty gift is valid.
        if (s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] == false) {
            revert LoyaltyProgram__LoyaltyGiftInvalid();
        }

        // check if requirements are met. Reverts with reason WHY not met. 
        ILoyaltyGift(loyaltyGiftAddress).requirementsLoyaltyGiftMet(loyaltyCardAddress, loyaltyGiftId, loyaltyPoints); 

        // Effect.
        // 1) set executed to true..
        requestExecuted[signature] = true;
        // 2) add 1 to nonce
        s_nonceLoyaltyCard[loyaltyCardAddress] = ++s_nonceLoyaltyCard[loyaltyCardAddress];

        // Interact.
        // 3) retrieve loyalty points from customer
        _safeTransferFrom(loyaltyCardAddress, s_owner, 0, loyaltyPoints, "");
        // and 4), if gift is tokenised, transfer voucher.
        if (ILoyaltyGift(loyaltyGiftAddress).getIsVoucher(loyaltyGiftId) == 1) {
            // refactor into MockLoyaltyGift(loyaltyGift)._safeTransferFrom ? 
            transferLoyaltyVoucher(s_owner, loyaltyCardAddress, loyaltyGiftAddress, loyaltyGiftId); 
        }
    }


    /**
     * @notice redeems loyaltyVoucher for loyalty Gift by calling external contract, using a signed message from customer.
     *
     * @param _voucher description of gift voucher. 
     * @param loyaltyGiftAddress address of loyalty gift to claim
     * @param loyaltyGiftId id of loyalty gift to claim 
     * @param loyaltyCardId id of loyalty card whose points are used to claim gift. 
     * @param customerAddress address of customer that makes the claim. 
     * @param signature customer (EIP-712) signature used to sign message.  
     *
     * @dev only one voucher can be redeemed per call.
     * @dev only loyaltyCards minted through this loyalty program can be used redeem loyalty vouchers.
     * @dev £security removed nonReentrant guard as CEI (Check-Effect-Interaction) structure was followed and the function is onlyOwner. This is correct - right? 
     * @dev if customer does not own TBA / loyalty card it will revert at ERC6551 account.
     *
     * - emits a TransferSingle event
     */
    function redeemLoyaltyVoucher(
        string memory _voucher,
        address loyaltyGiftAddress,
        uint256 loyaltyGiftId,
        uint256 loyaltyCardId,
        address customerAddress,
        bytes memory signature
    ) external onlyOwner {
        address loyaltyCardAddress = getTokenBoundAddress(loyaltyCardId);
        
        // filling up RequestGift struct with provided data. 
        redeemMessage.from = loyaltyCardAddress;
        redeemMessage.to = address(this);
        redeemMessage.voucher = _voucher;
        redeemMessage.nonce = s_nonceLoyaltyCard[loyaltyCardAddress];
        
        // creating digest hash 
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRedeemVoucher(redeemMessage));

        // Retrieving signer address from digest and signature.  
        address signer = digest.recover(signature);

        // Checks. 
        // Check that this digest hasn't already been executed
        if (requestExecuted[signature] == true) {
            revert LoyaltyProgram__RequestAlreadyExecuted();
        }

        // check if signer is customer address 
        if (signer != customerAddress) {
            revert LoyaltyProgram__RequestInvalid();
        }

        // check if signer owns loyaltyCard
        if (balanceOf(signer, loyaltyCardId) == 0) {
            revert LoyaltyProgram__NotOwnerLoyaltyCard();
        }

        // check if loyalty Voucher is valid.
        if (s_LoyaltyVouchersRedeemable[loyaltyGiftAddress][loyaltyGiftId] == false) {
            revert LoyaltyProgram__LoyaltyVoucherInvalid();
        }

        // Execute.
        // 1) set executed to true..
        requestExecuted[signature] = true;
        s_nonceLoyaltyCard[loyaltyCardAddress] = ++s_nonceLoyaltyCard[loyaltyCardAddress];

        // Interact.
        // 2) retrieve loyalty voucher
        transferLoyaltyVoucher(loyaltyCardAddress, s_owner, loyaltyGiftAddress, loyaltyGiftId); 
    }

    /* Implementation ERC standards */ 

    /**
     * @notice implementation ERC-1155 receipt check. See https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155Receiver-onERC1155Received-address-address-uint256-uint256-bytes- 
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @notice implementation ERC-1155 receipt check. See https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155Receiver-onERC1155Received-address-address-uint256-uint256-bytes- 
     */
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @notice implementation for ERC-165 interface id. 
     * 
     * @param interfaceId: id of interface 
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (IERC165, ERC1155) returns (bool) {
      return 
        interfaceId == type(ILoyaltyProgram).interfaceId || 
        super.supportsInterface(interfaceId);
    }

    /* internal */

    /**
     * @dev Loyalty points can only transferred to
     * - loyalty cards.
     * - owner of this contracts, s_owner - when paying for gifts.
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
                if ( // if ...
                    s_LoyaltyCards[to] == false && // points are not transferred to loyalty cards...
                    to != s_owner // ...or to owner...
                ) {
                    // ...revert
                    revert LoyaltyProgram__TransferDenied();
                }
            }
            // loyalty cards cannot be transferred to other loyalty cards. 
            if (ids[i] != LOYALTY_POINTS_ID) {
                if (s_LoyaltyCards[to] == true) {
                    revert LoyaltyProgram__TransferDenied();
                }
            }
        }
        super._update(from, to, ids, values);
    }

    function _createTokenBoundAccount(uint256 _loyaltyCardId) internal returns (address tokenBoundAccount) {
        tokenBoundAccount = ERC6551Registry(ERC6551_REGISTRY).createAccount(
            s_erc6551_account, SALT, block.chainid, address(this), _loyaltyCardId
        );

        return tokenBoundAccount;
    }

    /* private functions */ 
    /**
     * @notice helper function to create EIP712 Domain separator.
     */
    function hashDomain(EIP712Domain memory domain) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(domain.name)),
                keccak256(bytes(domain.version)),
                domain.chainId,
                domain.verifyingContract
            )
        );
    }

    /**
     * @notice helper function to create digest hash from RequestGift struct.
     */
    function hashRequestGift(RequestGift memory message) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                // keccak256(bytes("RequestGift(uint256 nonce)")),
                keccak256(bytes("RequestGift(address from,address to,string gift,string cost,uint256 nonce)")),
                message.from,
                message.to,
                keccak256(bytes(message.gift)),
                keccak256(bytes(message.cost)),
                message.nonce
            )
        );
    }

    /**
     * @notice helper function to create digest hash from RedeemVoucher struct.
     */
    function hashRedeemVoucher(RedeemVoucher memory message) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(bytes("RedeemVoucher(address from,address to,string voucher,uint256 nonce)")),
                message.from,
                message.to,
                keccak256(bytes(message.voucher)),
                message.nonce
            )
        );
    }

    /* Getter functions */
    function getOwner() external view returns (address) {
        return s_owner;
    }

    function getTokenBoundAddress(uint256 _loyaltyCardId) public view returns (address tokenBoundAccount) {
        tokenBoundAccount = ERC6551Registry(ERC6551_REGISTRY).account(
            s_erc6551_account, SALT, block.chainid, address(this), _loyaltyCardId 
        );
        return tokenBoundAccount;
    }

    function getLoyaltyGiftIsClaimable(address loyaltyGiftAddress, uint256 loyaltyGiftId)
        external
        view
        returns (bool)
    {
        return s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId];
    }

    function getLoyaltyGiftIsRedeemable(address loyaltyGiftAddress, uint256 loyaltyGiftId)
        external
        view
        returns (bool)
    {
        return s_LoyaltyVouchersRedeemable[loyaltyGiftAddress][loyaltyGiftId];
    }

    function getNumberLoyaltyCardsMinted() external view returns (uint256) { // £improve can this bea public state var? -- this would mean I don't need this getter function 
        return s_loyaltyCardCounter;
    }

    function getBalanceLoyaltyCard(address loyaltyCardAddress) external view returns (uint256) {
        return balanceOf(loyaltyCardAddress, 0);
    }

    function getNonceLoyaltyCard(address loyaltyCardAddress) external view returns (uint256) {
        return s_nonceLoyaltyCard[loyaltyCardAddress];
    }
}

// Notes to self (£todo): 
// When reviewing this code, check: https://github.com/transmissions11/solcurity
// see also: https://github.com/nascentxyz/simple-security-toolkit

// Structure contract // -- from Patrick Collins. 
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
