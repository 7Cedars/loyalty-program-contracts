// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // removed
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC6551Account} from "../src/interfaces/IERC6551Account.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ILoyaltyGift} from "./interfaces/ILoyaltyGift.sol";

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC6551Registry} from "../test/mocks/ERC6551Registry.sol";
import {LoyaltyCard6551Account} from "./LoyaltyCard6551Account.sol";
import {LoyaltyGift} from "../test/mocks/LoyaltyGift.sol";

/**
 * @dev THIS CONTRACT HAS NOT BEEN AUDITED. WORSE: TESTING IS INCOMPLETE. DO NOT DEPLOY ON ANYTHING ELSE THAN A TEST CHAIN! 
 * 
 * @title Loyalty Program 
 * @author Seven Cedars
 * @notice This contract allows for loyalty *points* to be distributed to loyalty *cards* that 
 *  - are locked in for use with the (single) loyalty *program* that minted the points and cards; 
 *  - points can be exchanged for *gifts* or *vouchers* through __external__ contracts following ILoyaltyGift interface; 
 *  - these external LoyaltyGift contracts are (de)selected at the LoyaltyProgram; 
 *  - vouchers are saved at Loyalty cards and locked in for use with the loyalty program that minted these cards. 
 *  - all gas costs are covered by the Loyalty Program contract.
 * In short, it aims to provide a light weight, composable, gas efficient framework for blockchain based customer engagement programs. 
 * 
 * @dev It builds on the following standards 
 *  - ERC-1155 (Multi-Token Standard): the Loyalty Program contract mints fungible points and non-fungible loyalty Cards; external contracts can mint semi-fungible vouchers. 
 *  - ERC-6551 (Non-fungible Token Bound Accounts): Loyalty Cards are transformed into Token Based Accounts using ERC-6551 registry.   
 *  - EIP-712 (Typed structured data hashing and signing): customer requests are executed through signed messages (transferred in front-end app as Qr codes) to the vendor. It allows the vendor to cover all gas costs. 
 * The project is meant as a showcase of using fungible, semi-fungible and non-fungible tokens (NFTs) as a utility, rather than store of value.
 * 
 * @dev Central objects / concepts in this framework
 *  - Loyalty Program: this contract. Mints points and cards, (de)selects external loyalty programs. Inherits ERC1155 & IERC1155Receiver. 
 *  - Vendor: EOA that created the LoyaltyProgram contract. More advanced governance options are planned for future versions.   
 *  - Customer: EOA that owns a loyalty card. Loyalty Cards can be freely transferred to other EOAs.   
 *  - Loyalty Points: Fungible token minted at loyalty program by *vendor*.   
 *  - Loyalty Cards: non-fungible token minted at loyalty program by *vendor*. They are registered at ERC-6551 registry and give access to a token based account.
 *  - Loyalty Gifts: a ERC-1155 based contract that holds a 'requirementsMet' function providing a boolean result: True if a contract specific requirement was met. (This most often is transfer of points, but can be virtually anything.)  
 *  - Loyalty Vouchers: optional semi-fungible tokens minted by *loyalty program* at external gift contract. They can be transferred to loyalty card when loyalty gift resulted in true. Vouchers can be used for delayed exchange of gift.  
 *
 * @dev A few gotchas: 
 *  - points and vouchers are operated by _different_ contracts (vendor versus loyalty program).
 *  - ... 
 */

/**
 * Acknowledgments 
 * 
 * - This project was build while following Patrick Collins' "Learn Solidity, Blockchain Development, & Smart Contracts" Youtube course. 
 *   Not only does the course come highly recommended (it's really a fantastic course!) many parts of this repo started out as direct rip offs from his examples. 
 *   I have tried to note all specific cases, but please forgive me if / when  I missed some.
 * 
 * - The Foundry book (and example of EIP0-712 was immensly helpful; as was learnweb3's covering gas cost tutorial. 
 *   see: https://learnweb3.io/lessons/using-metatransaction-to-pay-for-your-users-gas
 *   and see: https://book.getfoundry.sh/tutorials/testing-eip712
 *   this also goes for: https://medium.com/coinmonks/eip-712-example-d5877a1600bd
 * 
 * - Regarding ERC-6551. The website tokenbound.org was very helpful. 
 *   ... todo. 
 */

contract LoyaltyProgram is ERC1155, IERC1155Receiver { // removed: ReentrancyGuard
    /* errors */
    error LoyaltyProgram__OnlyOwner();
    error LoyaltyProgram__TransferDenied();
    error LoyaltyProgram__RequestAlreadyExecuted();
    error LoyaltyProgram__NotOwnerLoyaltyCard();
    error LoyaltyProgram__RequestInvalid();
    error LoyaltyProgram__LoyaltyGiftInvalid();
    error LoyaltyProgram__LoyaltyVoucherInvalid();
    error LoyaltyProgram__IncorrectInterface(address loyaltyGift);

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

    // Redeem voucher message struct
    struct RedeemVoucher {
        address from;
        address to;
        string voucher;
        uint256 nonce;
    }
    
    address private immutable s_owner;
    bytes32 private immutable DOMAIN_SEPARATOR;

    mapping(bytes32 => uint256 executed) private requestExecuted; // 0 = false & 1 = true.
    mapping(address loyaltyCard => uint256 nonce) private s_nonceLoyaltyCard;
    mapping(address loyaltyCardAddress => uint256 exists) private s_LoyaltyCards; // 0 = false & 1 = true.
    mapping(address loyaltyGiftAddress => mapping(uint256 loyaltyGiftId => uint256 exists)) private s_LoyaltyGiftsClaimable; // 0 = false & 1 = true.
    mapping(address loyaltyGiftAddress => mapping(uint256 loyaltyGiftId => uint256 exists)) private s_LoyaltyVouchersRedeemable; // 0 = false & 1 = true.
    uint256 private s_loyaltyCardCounter;
    ERC6551Registry public s_erc6551Registry;
    LoyaltyCard6551Account public s_erc6551Implementation;

    /* Events */
    event DeployedLoyaltyProgram(address indexed owner, string name, string version);
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
     * @notice constructor function for Loyalty program contract.
     * 
     * @param _uri the uri linked to the loyalty program. See for example layout of this Uri the LoyaltyPrograms folder.
     * @param _name the name of the Loyalty Program
     * @param _version the version of the Loyalty Program 
     * @param erc6551Registry address of registry. This address is often the same but can change with test chains, versions, specific deployments of registries, etc. 
     * @param erc6551Implementation this is a bespoke - loyalty program specific - deployment of a standard ERC6551 account example from token bound.  
     *
     * @dev s_owner is now set as msg-sender and cannot be changed later on. This is on the list to change. 
     * @dev input for erc6551Registry and erc6551Implementation addresses. This is to allow for easy testing (Note that addresses on test networks for registry might differ from standard addresses.)
     * @dev also set up of ERC-712 DOMAIN_SEPARATOR. 
     *
     * emits a DeployedLoyaltyProgram event.
     */
    constructor(string memory _uri, string memory _name, string memory _version, address erc6551Registry, address payable erc6551Implementation) ERC1155(_uri) {
        s_owner = msg.sender;
        s_loyaltyCardCounter = 0;
        s_erc6551Registry = ERC6551Registry(erc6551Registry);
        s_erc6551Implementation = LoyaltyCard6551Account(erc6551Implementation);

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
     * @notice mints loyaltyCards. Each is a non-fungible token (NFT), that is linked to a token bound account. - this function is a real gas guzzler. 
     * 
     * @param numberOfLoyaltyCards amount of loyaltycards to be minted.
     *
     * @dev only owner of program can mint loyalty cards.
     * @dev first id of card is 1. (not 0, this id is reserved for loyalty points). 
     * @dev no limit to the amount of cards to mint - when to many are minted, gas limits kick in. 
     * @dev each address of Token Bound Account (TBA) is stored in s_LoyaltyCards.
     * @dev //security// it should be (and I think is now) impossible to mint more than one loyaltyCard of the same Id. 
     * This is crucial as the LoyaltyCard6551Account contract does not have a check for this - due to this contract being ERC-1155 based (instead of ERC-721). 
     * if more than one card of the same id are minted, you _will_ have a loyalty Card with multiple owners. 
     *
     * - emits a transferBatch event.
     */
    function mintLoyaltyCards(uint256 numberOfLoyaltyCards) public onlyOwner {
        uint256[] memory loyaltyCardIds = new uint256[](numberOfLoyaltyCards);
        uint256[] memory mintNfts = new uint256[](numberOfLoyaltyCards);
        uint256 counter = s_loyaltyCardCounter;

        /**
         * @dev //security// note that I log these addresses as TBAs BEFORE they have actually been minted.
         */
        for (uint256 i; i < numberOfLoyaltyCards; i++) {
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
     * //security// //todo// If contract does not have LoyaltyGift interface, it should revert. NOT YET IMPLEMENTED. 
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
        // CAUSES many reverts :D Needs bug fixing...
        // bytes4 interfaceId = type(ILoyaltyGift).interfaceId;
        // if (ERC165Checker.supportsERC165InterfaceUnchecked(loyaltyGift, interfaceId) == false) {
        //     revert LoyaltyProgram__IncorrectInterface(loyaltyGift);
        // }
        s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] = 1;
        s_LoyaltyVouchersRedeemable[loyaltyGiftAddress][loyaltyGiftId] = 1;
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
        if (s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] == 0) {
            revert LoyaltyProgram__LoyaltyGiftInvalid();
        }
        s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] = 0;
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
     * @dev Calling this function is an extreme measure and should only be used on extreme cases (malfunction, hack, etc).
     * @dev it also removes gifts from claimable whitelist, avoiding scenario where voucher can be claimed but not redeemed.
     * @dev only owner can remove contracts from whitelist.
     *
     * - emits an RemovedLoyaltyGiftRedeemable event.
     */
    function removeLoyaltyGiftRedeemable(address loyaltyGiftAddress, uint256 loyaltyGiftId) public onlyOwner {
        if (s_LoyaltyVouchersRedeemable[loyaltyGiftAddress][loyaltyGiftId] == 0) {
            revert LoyaltyProgram__LoyaltyGiftInvalid();
        }
        s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] = 0;
        s_LoyaltyVouchersRedeemable[loyaltyGiftAddress][loyaltyGiftId] = 0;

        emit RemovedLoyaltyGiftRedeemable(loyaltyGiftAddress, loyaltyGiftId);
    }

    /**
     * @dev mint loyaltyGifts at external loyaltyGift contract.
     * @param loyaltyGiftAddress address of loyalty gift contract.
     * @param numberOfVouchers amount of vouchers to be minted.
     *
     * @notice the limit of loyalty vouchers that customers can be gifted is limited by the amount of vouchers minted by the owner of loyalty program.
     * @notice only owner can remove contracts from whitelist.
     *
     * - emits transferSingle event when one vouchers is minted.
     * - emits transferBatch when more vouchers are minted?
     */
    function mintLoyaltyVouchers(
        address loyaltyGiftAddress,
        uint256[] memory loyaltyGiftIds,
        uint256[] memory numberOfVouchers
    ) public onlyOwner {
        LoyaltyGift(loyaltyGiftAddress).mintLoyaltyVouchers(loyaltyGiftIds, numberOfVouchers);
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
     * @dev //security// removed nonReentrant guard as CEI (Check-Effect-Interaction) structure was followed. This is correct - right? 
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
    ) external onlyOwner {
        address loyaltyCardAddress = getTokenBoundAddress(loyaltyCardId);

        // filling up RequestGift struct with provided data. 
        RequestGift memory message;
        message.from = loyaltyCardAddress;
        message.to = address(this);
        message.gift = _gift;
        message.cost = _cost;
        message.nonce = s_nonceLoyaltyCard[loyaltyCardAddress];
        
        // creating digest. 
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message));

        // using this digest and signature to recover customer address 
        address signer = digest.recover(signature);

        // Checks. 
        // Checks if signer equals customer address
        if (signer != customerAddress) {
            revert LoyaltyProgram__RequestInvalid();
        }

        // check if signer owns loyaltyCard
        if (balanceOf(signer, loyaltyCardId) == 0) {
            revert LoyaltyProgram__NotOwnerLoyaltyCard();
        }

        // Check that this signature hasn't already been executed
        if (requestExecuted[digest] == 1) {
            revert LoyaltyProgram__RequestAlreadyExecuted();
        }

        // check if Loyalty gift is valid.
        if (s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId] == 0) {
            revert LoyaltyProgram__LoyaltyGiftInvalid();
        }

        // Effect.
        // 1) set executed to true..
        requestExecuted[digest] = 1;
        // 2) add 1 to nonce
        s_nonceLoyaltyCard[loyaltyCardAddress] = s_nonceLoyaltyCard[loyaltyCardAddress] + 1;

        // Interact.
        // 3) retrieve loyalty points from customer
        _safeTransferFrom(loyaltyCardAddress, s_owner, 0, loyaltyPoints, "");
        // and 4) transfer voucher.
        LoyaltyGift(loyaltyGiftAddress).issueLoyaltyGift(loyaltyCardAddress, loyaltyGiftId, loyaltyPoints);
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
     * @dev //security// removed nonReentrant guard as CEI (Check-Effect-Interaction) structure was followed. This is correct - right? 
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
        RedeemVoucher memory message;
        message.from = loyaltyCardAddress;
        message.to = address(this);
        message.voucher = _voucher;
        message.nonce = s_nonceLoyaltyCard[loyaltyCardAddress];
        
        // creating digest hash 
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRedeemVoucher(message));

        // Retrieving signer address from digest and signature.  
        address signer = digest.recover(signature);

        // Checks. 
        // check if signer is customer address 
        if (signer != customerAddress) {
            revert LoyaltyProgram__RequestInvalid();
        }

        // check if signer owns loyaltyCard
        if (balanceOf(signer, loyaltyCardId) == 0) {
            revert LoyaltyProgram__NotOwnerLoyaltyCard();
        }

        // Check that this digest hasn't already been executed
        if (requestExecuted[digest] == 1) {
            revert LoyaltyProgram__RequestAlreadyExecuted();
        }

        // check if loyalty Voucher is valid.
        if (s_LoyaltyVouchersRedeemable[loyaltyGiftAddress][loyaltyGiftId] == 0) {
            revert LoyaltyProgram__LoyaltyVoucherInvalid();
        }

        // Execute.
        // 1) set executed to true..
        requestExecuted[digest] = 1;
        s_nonceLoyaltyCard[loyaltyCardAddress] = s_nonceLoyaltyCard[loyaltyCardAddress] + 1;

        // Interact.
        // 2) redeem loyalty voucher
        LoyaltyGift(loyaltyGiftAddress).reclaimLoyaltyVoucher(loyaltyCardAddress, loyaltyGiftId);
    }

    /**
     * CONTINUE HERE WITH ADDING NATSPECS. 
     */

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
                    s_LoyaltyCards[to] == 0 // points are not transferred to loyalty cards...
                        && to != s_owner // ...or to owner...
                ) {
                    // ...revert
                    revert LoyaltyProgram__TransferDenied();
                }
            }
            if (ids[i] != LOYALTY_POINTS_ID) {
                if (s_LoyaltyCards[to] == 1) {
                    revert LoyaltyProgram__TransferDenied();
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

    function getLoyaltyGiftsIsClaimable(address loyaltyGiftAddress, uint256 loyaltyGiftId)
        external
        view
        returns (uint256)
    {
        return s_LoyaltyGiftsClaimable[loyaltyGiftAddress][loyaltyGiftId];
    }

    function getLoyaltyGiftsIsRedeemable(address loyaltyGiftAddress, uint256 loyaltyGiftId)
        external
        view
        returns (uint256)
    {
        return s_LoyaltyVouchersRedeemable[loyaltyGiftAddress][loyaltyGiftId];
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



// Notes to self (todo): 
// When reviewing this code, check: https://github.com/transmissions11/solcurity
// see also: https://github.com/nascentxyz/simple-security-toolkit
// see: https://solidity-by-example.org/structs/ re how to create structs


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
