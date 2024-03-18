// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// needs a setup / constructor that 
// - set ups 0 - 3 loyalty programs 
// - set ups 0 - 3 loyalty gift programs. 
// modifier that has programs select, mint 0 - many points, cards, vouchers. 

// Functions: 
// - safe transfer any token id to any (card, program) address that emerged from setup.    
// - claim gifts from loyalty card at any loyalty program 
// - redeem voucher (if availabe at card) at any loyalty program. 

// if max 3 loyalty programs, should still be about 30% succesful :D  
// Note: should also test for scenarios where no program or gifts exist 


// import {Test} from "forge-std/Test.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployLoyaltyProgram} from "../../../script/DeployLoyaltyProgram.s.sol";
import {DeployMockLoyaltyGifts} from "../../../script/DeployLoyaltyGifts.s.sol";
import {LoyaltyProgram} from "../../../src/LoyaltyProgram.sol" ;
import {LoyaltyGift} from "../../mocks/LoyaltyGift.sol" ;
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {LoyaltyCard6551Account} from "../../../src/LoyaltyCard6551Account.sol";


contract ContinueOnRevertHandlerCards is Test  {
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;

  DeployLoyaltyProgram deployerLP;
  DeployMockLoyaltyGifts deployerLT;
  uint256 INITIAL_SUPPLY = 260000000; 

  address[] userAddresses; 
  uint256[] userPrivatekeys; 
  LoyaltyProgram[] loyaltyPrograms;
  address[] loyaltyCards;
  LoyaltyGift[] loyaltyGifts;
  address[] allAddresses;
  string[] names; 
  uint256 selectedCard; 
  LoyaltyCard6551Account loyaltyCardAccount; 
  
  HelperConfig helperConfig; 
  ContinueOnRevertHandlerCards handler;
  uint256 numberLCards; 

  struct CardData {
    address cardAddress; 
    string owner; 
  }
  CardData[] cardAddresses;
  CardData[] allCardAddresses;

  struct ProgramData {
    LoyaltyProgram loyaltyProgram; 
    string owner; 
    CardData[] loyaltyCards; 
    HelperConfig config; 
  }
  ProgramData[] programsData;

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

  // domain seperator.
  bytes32 internal DOMAIN_SEPARATOR; 
  
  constructor( 
    LoyaltyProgram[] memory _loyaltyPrograms,  
    address[] memory _loyaltyCards,  
    LoyaltyGift[] memory _loyaltyGifts, 
    HelperConfig _helperConfig
    ) {
      loyaltyPrograms = _loyaltyPrograms;
      loyaltyCards = _loyaltyCards; 
      loyaltyGifts = _loyaltyGifts;
      helperConfig = _helperConfig;
      for (uint256 i = 0; i < loyaltyPrograms.length; i++) { allAddresses.push(address(loyaltyPrograms[i])); } 
      for (uint256 i = 0; i < loyaltyCards.length; i++) { allAddresses.push(loyaltyCards[i]); } 
      for (uint256 i = 0; i < loyaltyGifts.length; i++) { allAddresses.push(address(loyaltyGifts[i])); } 
      
    (address ash, uint256 ashKey) = makeAddrAndKey("ash"); 
    (address cedar, uint256 cedarKey) = makeAddrAndKey("cedar"); 
    (address berch, uint256 berchKey) = makeAddrAndKey("berch");  
    (address oak, uint256 oakKey) = makeAddrAndKey("oak"); 
    (address alder, uint256 alderKey) = makeAddrAndKey("alder"); 
    userAddresses = [ash, cedar, berch, oak, alder]; 
    userPrivatekeys = [ashKey, cedarKey, berchKey, oakKey, alderKey]; 

    // distribute cards to users 
    for (uint256 i = 0; i < loyaltyPrograms.length; i++) {
      // note that 0 = id for points, so loyalty cards start at 1. 
      for (uint256 j = 1; j < (loyaltyCards.length / loyaltyPrograms.length); j++) {
        address owner; 
        owner = loyaltyPrograms[i].getOwner(); 
        vm.prank(owner); 
        loyaltyPrograms[i].safeTransferFrom(
          owner, 
          userAddresses[j], 
          j, 
          1, 
          ""
          ); 
        }
      }
    }

    // NB: DO NOT DELETE THE FOLLOWING. Do want to test again in the future. 
    // but for now, ALWAYS reverts - as it should.  
    // // have a random card try to transfer to random other known address: card, program or gift contract 
    // function transferPoints(
    //   uint256 loyaltyProgramSeed, 
    //   uint256 loyaltyCardSeed, 
    //   uint256 receiverSeed, 
    //   uint256 amountPointsSeed
    // ) public {
    //   // NB: we need to have the owner of the card to make transfer. 
    //   // Hence first select program, then card. As cards have not been transferred, owner = program. 
    //   LoyaltyProgram loyaltyProgram = _getLoyaltyProgram(loyaltyProgramSeed);
    //   address receiver = _getAddress(receiverSeed); 
    //   uint256 numberCards = loyaltyProgram.getNumberLoyaltyCardsMinted(); 
    //   selectedCard = loyaltyCardSeed % numberCards; 
    //   address selectedCardAddress = loyaltyProgram.getTokenBoundAddress(selectedCard); 
    //   address owner = userAddresses[selectedCard]; 
    //   uint256 amountPoints = amountPointsSeed % 50; // low amount so not bounced less often on account of not having sufficient balance. 
      
    //   vm.prank(owner); 
    //   LoyaltyCard6551Account(payable(selectedCardAddress)).executeCall(
    //           payable(address(loyaltyProgram)),
    //           0,
    //           abi.encodeCall(
    //               loyaltyProgram.safeTransferFrom,
    //                 (selectedCardAddress, 
    //                 receiver, 
    //                 0, 
    //                 amountPoints, 
    //                 ""
    //               )
    //           )
    //       );
    // }

    // // have ANY known card (with the correct owner) try to claim gift at ANY known loyalty Program
    function claimGifts(
      uint256 loyaltyProgramSeed, 
      uint256 giftProgramSeed, 
      uint256 giftIdSeed, 
      uint256 loyaltyCardSeed
    ) public {
      // selecting random program & random card of this program 
      LoyaltyProgram loyaltyProgram = _getLoyaltyProgram(loyaltyProgramSeed);
      uint256 numberCards = loyaltyProgram.getNumberLoyaltyCardsMinted(); 
      selectedCard = loyaltyCardSeed % numberCards;

      address selectedCardAddress = loyaltyProgram.getTokenBoundAddress(selectedCard); 
      address ownerProgram = loyaltyProgram.getOwner(); 
      address ownerCard = userAddresses[selectedCard]; // The way the test is setup, user 0 always has card 0.  
      uint256 privateKeyownerCard = userPrivatekeys[selectedCard]; 

      // selecting random gift program & random gift of this program. 
      LoyaltyGift giftProgram = _getGiftProgram(giftProgramSeed); 
      // uint256[] memory tokenised = giftProgram.getTokenised();
      uint256 giftId = giftIdSeed % 2 + 3; // for now, ALWAYS tokenised gifts are at positions 3, 4, 5. 

      // creating & signing request message - results in signature. 
      DOMAIN_SEPARATOR = hashDomainSeparator(address(loyaltyProgram)); 
      RequestGift memory message = RequestGift({
          from: selectedCardAddress,
          to: address(loyaltyProgram),
          gift: "This is a test gift",
          cost: "enough points",
          nonce: 0
      });
      bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRequestGift(message));
      (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKeyownerCard, digest);
      bytes memory signature = abi.encodePacked(r, s, v);

      // owner of loyaltyprogram uses signature when executing claimLoyaltyGift function.
      vm.prank(ownerProgram);
      loyaltyProgram.claimLoyaltyGift(
        "This is a test gift", // string memory _gift,
        "enough points", // string memory _cost,
        address(giftProgram), // address loyaltyGiftsAddress,
        giftId, // uint256 loyaltyGiftId,
        selectedCard, // uint256 loyaltyCardId,
        ownerCard, // address customerAddress,
        5000, // uint256 loyaltyPoints, 5000 = max cost gift + min transaction. 
        signature // bytes memory signature
      );
    }

    // // have ANY known card with voucher try to redeem voucher at ANY known loyalty Program
    // WIP
    function redeemVoucher(
      uint256 loyaltyCardSeed
    ) public {
      // randomly select loyalty  card; 
      LoyaltyGift selectedGiftProgram; 
      LoyaltyProgram selectedLoyaltyProgram; 
      address selectedCardAddress; 
      address selectedUser; 
      uint256 selectedUserPrivateKey;  
      uint256 cardBalance;

      console.log("redeem voucher called."); 

      selectedCardAddress = loyaltyCards[loyaltyCardSeed % loyaltyCards.length]; 
      selectedUser = userAddresses[loyaltyCardSeed % loyaltyCards.length]; // NB: this only works because index of cards = index of user. 
      selectedUserPrivateKey = userPrivatekeys[loyaltyCardSeed % loyaltyCards.length]; 

      for (uint256 i; i < loyaltyGifts.length; i++) {
        for (uint256 voucherId = 2; voucherId < 6; voucherId++) {
          // find a voucher that is owned. 
          selectedGiftProgram = loyaltyGifts[i]; 
          cardBalance = selectedGiftProgram.balanceOf(selectedCardAddress, voucherId);
          console.logUint(cardBalance); 

          // then try to redeem at any Loyalty Program. 
          if (cardBalance != 0) {
            console.log("redeem voucher triggered!"); 

            LoyaltyProgram loyaltyProgram; 
            loyaltyProgram = programsData[0].loyaltyProgram; 
            address ownerProgram; 
            ownerProgram = loyaltyProgram.getOwner(); 

            DOMAIN_SEPARATOR = hashDomainSeparator(address(loyaltyProgram)); 
            RedeemVoucher memory message = RedeemVoucher({
              from: selectedCardAddress,
              to: address(loyaltyProgram),
              voucher: "This is a test redeem",
              nonce: 1
            });
            bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRedeemVoucher(message));
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(selectedUserPrivateKey, digest);
            bytes memory signature = abi.encodePacked(r, s, v);
            
            vm.prank(ownerProgram);
            try 
              loyaltyProgram.redeemLoyaltyVoucher(
                "This is a test redeem", // string memory _gift,
                address(selectedGiftProgram), // address loyaltyGiftsAddress,
                voucherId, // uint256 loyaltyGiftId,
                selectedCard, // uint256 loyaltyCardId,
                selectedUser, // address customerAddress,
                signature) // bytes memory signature
              { } catch {
                console.log("redeem failed"); 
              }
            
          }
        }
      }
    }
              

    // Helper Functions 
     function _getLoyaltyProgram( uint256 loyaltyProgramSeed ) private view returns (LoyaltyProgram) 
    {
      return loyaltyPrograms[loyaltyProgramSeed % loyaltyPrograms.length];
      }

    function _getGiftProgram( uint256 giftProgramSeed ) private view returns (LoyaltyGift) 
    {
      return loyaltyGifts[giftProgramSeed % loyaltyGifts.length];
      }

    // NB: I DO need a list of ALL loyalty Card Addresses! 
    function _getLoyaltyCard( uint256 loyaltyCardSeed ) private view returns (address) 
    {
      return loyaltyCards[loyaltyCardSeed % loyaltyCards.length];
      }
    
    function _getAddress( uint256 addressSeed ) private view returns (address) 
    {
      return allAddresses[addressSeed % allAddresses.length];
      }
    
    function _getPrivateKey( address userAddress ) private view returns (uint256) 
    {
      for (uint256 i = 0; i < userAddresses.length; i++) {
        if (userAddresses[i] == userAddress) {
          return userPrivatekeys[i];
          }
        }
        revert("no private key found"); 
      }
    
    function _redeemVoucher( 
      LoyaltyProgram loyaltyProgram, 
      LoyaltyGift giftProgram, 
      uint256 giftId, 
      address userAddress, 
      uint256 userPrivateKey, 
      address selectedCardAddress  
      ) private {
        address ownerProgram; 
        ownerProgram = loyaltyProgram.getOwner(); 
        
        // creating & signing request message - results in signature. 
        DOMAIN_SEPARATOR = hashDomainSeparator(address(loyaltyProgram)); 
        RedeemVoucher memory message = RedeemVoucher({
            from: selectedCardAddress,
            to: address(loyaltyProgram),
            voucher: "This is a test redeem",
            nonce: 1
        });
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, hashRedeemVoucher(message));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // owner of loyaltyprogram uses signature when executing claimLoyaltyGift function.
        vm.prank(ownerProgram);
        loyaltyProgram.redeemLoyaltyVoucher(
          "This is a test redeem", // string memory _gift,
          address(giftProgram), // address loyaltyGiftsAddress,
          giftId, // uint256 loyaltyGiftId,
          selectedCard, // uint256 loyaltyCardId,
          userAddress, // address customerAddress,
          signature // bytes memory signature
        );
      }
    
      // helper function separator
    function hashDomainSeparator (address loyaltyProgram) private view returns (bytes32) {
        
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Loyalty Program")), // name
                keccak256(bytes("1")), // version
                block.chainid, // chainId
                loyaltyProgram //  0xBb2180ebd78ce97360503434eD37fcf4a1Df61c3 // verifyingContract
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

    // helper function hashRedeemVoucher
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
}
