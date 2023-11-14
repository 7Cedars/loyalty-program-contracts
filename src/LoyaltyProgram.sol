// When reviewing this code, check: https://github.com/transmissions11/solcurity
// see also: https://github.com/nascentxyz/simple-security-toolkit

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
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {LoyaltyToken} from "./LoyaltyToken.sol";
import {ERC6551Registry} from "./ERC6551Registry.sol";
import {ERC6551Account} from "./ERC6551Account.sol";
import {IERC6551Account} from "../src/interfaces/IERC6551Account.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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
    error LoyaltyProgram__LoyaltyTokenNotRecognised();
    error LoyaltyProgram__LoyaltyTokenNotRedeemable();
    error LoyaltyProgram__CardCanOnlyReceivePoints();
    error LoyaltyProgram__LoyaltyCardNotAvailable();
    error LoyaltyProgram__VendorLoyaltyCardCannotBeTransferred();
    error LoyaltyProgram__InSufficientPointsOnCard();
    error LoyaltyProgram__LoyaltyTokenNotOnCard();

    /* State variables */
    uint256 public constant LOYALTY_POINTS = 0;
    uint256 public constant INITIAL_SUPPLY_POINTS = 1e25;

    address private s_owner;
    mapping(address loyaltyTokenAddress => uint256 active) private s_LoyaltyTokensClaimable;
    mapping(address loyaltyTokenAddress => uint256 active) private s_LoyaltyTokensRedeemable; // 0 = false & 1 = true.
    mapping(address loyaltyCardAddress => uint256 exists) private s_LoyaltyCards; // 0 = false & 1 = true.
    uint256 private s_loyaltyCardCounter;
    ERC6551Registry public s_erc6551Registry;
    ERC6551Account public s_erc6551Implementation;

    /* Events */
    event AddedLoyaltyTokenContract(address indexed loyaltyToken);
    event RemovedLoyaltyTokenClaimable(address indexed loyaltyToken);
    event RemovedLoyaltyTokenRedeemable(address indexed loyaltyToken);

    /* Modifiers */
    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert LoyaltyProgram__OnlyOwner();
        }
        _;
    }

    /**
     * 
     */
    constructor() ERC1155("https://ipfs.io/ipfs/QmcPwXFUayuEETYJvd3QaLU9Xtjkxte9rgBgfEjD2MBvJ5.json") {
        // still have to check if this indeed gives out same uri for each NFT minted.
        s_owner = msg.sender;
        s_loyaltyCardCounter = 0;
        s_erc6551Registry = new ERC6551Registry();
        s_erc6551Implementation = new ERC6551Account();

        // inserted these for testing. Will refactor soon. 
        // should start empty I think (for me to see )
        mintLoyaltyCards(25);
        mintLoyaltyPoints(INITIAL_SUPPLY_POINTS);
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
     * These contracts should follow the LoyaltyToken contract.  
     * The interface for this has not been written yet. 
     * 
     * @param loyaltyToken address of contract to be whitelisted.
     * @notice only owner can whitelist contracts.  
     * @notice at the moment it lacks interface test. To do. 
     * 
     * - emits a AddedLoyaltyTokenContract event
     */

    function addLoyaltyTokenContract(address loyaltyToken) public onlyOwner {
        // later additional checks will be added here.
        s_LoyaltyTokensClaimable[loyaltyToken] = 1;
        s_LoyaltyTokensRedeemable[loyaltyToken] = 1;
        emit AddedLoyaltyTokenContract(loyaltyToken);
    }

    /**
     * @dev remove a loyalty contract from whitelist to redeem loyalty points for a token. 
     * i.e. After calling this function, customers will not be able to 'claim' token.
     * @param loyaltyToken address of loyaltyToken to be removed from whitelist. 
     * 
     * @notice after calling this function customers can still redeem this token at vendor to 
     * receive gift, event, etc. Token cannot be claimed, but can still be redeemed. 
     * @notice only owner can remove contracts from whitelist. 
     * 
     * - emits an RemovedLoyaltyTokenClaimable event. 
     */
    function removeLoyaltyTokenClaimable(address loyaltyToken) public onlyOwner {
        if (s_LoyaltyTokensClaimable[loyaltyToken] == 0) {
            revert LoyaltyProgram__LoyaltyTokenNotRecognised();
        }
        s_LoyaltyTokensClaimable[loyaltyToken] = 0;
        emit RemovedLoyaltyTokenClaimable(loyaltyToken);
    }

    /**
     * @dev remove a loyalty contract from whitelist for its tokens to be redeemable. 
     * i.e. After calling this function, customers will not be able to 'redeem' this token.
     * @param loyaltyToken address of loyaltyToken to be removed from whitelist. 
     * 
     * @notice after calling this function customers cannot redeem this token at vendor to 
     * receive gift, event, etc. 
     * @notice it also removes token from claimable whitelist, avoiding scenario where token 
     * can be claimed but not redeemed. 
     * @notice only owner can remove contracts from whitelist. 
     * 
     * - emits an RemovedLoyaltyTokenRedeemable event. 
     */
    function removeLoyaltyTokenRedeemable(address loyaltyToken) public onlyOwner {
        if (s_LoyaltyTokensRedeemable[loyaltyToken] == 0) {
            revert LoyaltyProgram__LoyaltyTokenNotRecognised();
        }
        if (s_LoyaltyTokensClaimable[loyaltyToken] == 1) {
          s_LoyaltyTokensClaimable[loyaltyToken] = 0;
        }
        s_LoyaltyTokensRedeemable[loyaltyToken] = 0;
        emit RemovedLoyaltyTokenRedeemable(loyaltyToken);
    }

    /** 
     * @dev mint loyaltyTokens at external loyaltyToken contract. 
     * @param loyaltyTokenAddress address of loyalty token contract. 
     * @param numberOfTokens amount of tokens to be minted. 
     * 
     * @notice the limit of loyalty tokens that customers can claim is limited by 
     * the amount of tokens minted by the owner of loyalty program. 
     * @notice only owner can remove contracts from whitelist. 
     * @notice added nonReentrant guard. 
     * 
     * - emits transferBatch event --  #REALLY? not transferSingle? double check! 
     */
    function mintLoyaltyTokens(address loyaltyTokenAddress, uint256 numberOfTokens) public onlyOwner nonReentrant {
        LoyaltyToken(loyaltyTokenAddress).mintLoyaltyTokens(numberOfTokens);
    }


    /** 
     * @dev redeem loyaltyPoints for loyaltyToken by a Token Bound Account (the loyalty card). 
     * The loyalty card calls the requirement function of external loyaltyToken contract. 
     * @param loyaltyToken address of loyalty token contract. 
     * @param loyaltyPoints number of points send to claim token.  
     * @param loyaltyCardId id of the loyalty card used to call this function. 
     * 
     * @notice only one token can be claimed per call. 
     * @notice any loyaltyCard minted through loyalty program can redeem loyalty points. 
     * @notice added nonReentrant guard as CEI structure could not be 100% followed. 
     * @notice if customer does not own TBA / loyalty card it will revert at ERC6551 account.  
     * 
     * - emits a TransferSingle event 
     */
    function redeemLoyaltyPoints(address loyaltyToken, uint256 loyaltyPoints, uint256 loyaltyCardId)
        external
        nonReentrant
    {
        address loyaltyCardAddress = getTokenBoundAddress(loyaltyCardId);

        // checks
        if (loyaltyPoints >= balanceOf(loyaltyCardAddress, 0)) {
            revert LoyaltyProgram__InSufficientPointsOnCard();
        }
        if (s_LoyaltyTokensRedeemable[loyaltyToken] == 0) {
            revert LoyaltyProgram__LoyaltyTokenNotRedeemable();
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
        LoyaltyToken(loyaltyToken).claimNft(loyaltyCardAddress);
    }

    

    function redeemLoyaltyToken(address loyaltyToken, uint256 loyaltyTokenId, uint256 loyaltyCard)
        external
        nonReentrant
    {
        address loyaltyCardAddress = getTokenBoundAddress(loyaltyCard);
        if (LoyaltyToken(loyaltyToken).balanceOf(loyaltyCardAddress, loyaltyTokenId) == 0) {
            revert LoyaltyProgram__LoyaltyTokenNotOnCard();
        }
        // check if loyaltyToken is redeemable. 
        if (LoyaltyToken(loyaltyToken).balanceOf(loyaltyCardAddress, loyaltyTokenId) == 0) {
            revert LoyaltyProgram__LoyaltyTokenNotOnCard();
        }

        /// Token is send to
        safeTransferFrom(
            loyaltyCardAddress,
            address(1), // loyalty points are send to burner address.
            loyaltyTokenId,
            0,
            ""
        );

        // emits a transferSingle event. 
    }

    function getTokenBoundAddress(uint256 _loyaltyCardId) public view returns (address tokenBoundAccount) {
        tokenBoundAccount = s_erc6551Registry.account(
            address(s_erc6551Implementation), block.chainid, address(this), _loyaltyCardId, 3947539732098357
        );

        return tokenBoundAccount;
    }

    // I should try an delete these ones - and see what happens..
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
     * @dev Loyalty points and tokens can only transferred to
     * - other loyalty cards.
     * - loyalty token contracts.
     * - address(0) - to burn.
     * - owner of this contracts, s_owner (used ofr minting points).
     * LoyaltyCards can be transferred anywhere.
     * @dev All other params remain unchanged.
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override
    {
        for (uint256 i = 0; i < ids.length; ++i) {
            if (ids[i] == LOYALTY_POINTS) {
                if (
                    s_LoyaltyTokensClaimable[to] == 0
                        && s_LoyaltyCards[to] == 0  // points can be transferred to loyalty Token Contracts
                        && to != address(0) // points can be transferred to address(0) = burn address
                        && to != s_owner // points can be transferred to owner (address that minted points are transferred to)
                ) {
                    // All other addresses are no-go.
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

    function getLoyaltyToken(address loyaltyToken) external view returns (uint256) {
        return s_LoyaltyTokensClaimable[loyaltyToken];
    }

    function getNumberLoyaltyCardsMinted() external view returns (uint256) {
        return s_loyaltyCardCounter;
    }

    function getBalanceLoyaltyCard(uint256 loyaltyCardId) external view returns (uint256) {
        address loyaltyCardAddress = getTokenBoundAddress(loyaltyCardId);
        return balanceOf(loyaltyCardAddress, 0);
    }
}
