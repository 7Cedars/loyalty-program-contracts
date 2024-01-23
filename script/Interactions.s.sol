// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {ERC6551Account} from "../src/ERC6551Account.sol";
import {LoyaltyProgram} from "../src/LoyaltyProgram.sol";
import {MockLoyaltyGifts} from "../src/MockLoyaltyGifts.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract Interactions is Script {
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;
  ERC6551Account ercAccount;

  uint256 POINTS_TO_MINT = 500000000; 
  uint256 CARDS_TO_MINT = 5; 
  uint256[] GIFTS_TO_SELECT = [0, 3, 5];
  uint256[] TOKENS_TO_MINT = [3, 5]; 
  uint256[] AMOUNT_TOKENS_TO_MINT = [24, 34]; 
  uint256[] GIFTS_TO_DESELECT = [2]; 

  uint256 privateKey0 = vm.envUint("DEFAULT_ANVIL_KEY_0");
  address address0 = vm.addr(privateKey0); 
  uint256 privateKey1 = vm.envUint("DEFAULT_ANVIL_KEY_1");
  address address1 = vm.addr(privateKey1); 
  uint256 privateKey2 = vm.envUint("DEFAULT_ANVIL_KEY_2");
  address address2 = vm.addr(privateKey2); 
  uint256 privateKey3 = vm.envUint("DEFAULT_ANVIL_KEY_3");
  address address3 = vm.addr(privateKey3); 
  uint256 privateKey4 = vm.envUint("DEFAULT_ANVIL_KEY_4");
  address address4 = vm.addr(privateKey4); 

  function run() external {
    address loyaltyProgramAddress = 0x8464135c8F25Da09e49BC8782676a84730C318bC; // DevOpsTools.get_most_recent_deployment("LoyaltyProgram", block.chainid);
    LoyaltyProgram loyaltyProgram = LoyaltyProgram(payable(loyaltyProgramAddress)); 
    address loyaltyGiftsAddress = 0xbdEd0D2bf404bdcBa897a74E6657f1f12e5C6fb6; // DevOpsTools.get_most_recent_deployment("MockLoyaltyGifts", block.chainid);
    MockLoyaltyGifts loyaltyGiftsContract = MockLoyaltyGifts(payable(loyaltyGiftsAddress));

    // step 1: mint loyalty points and cards; 
    mintLoyaltyPoints(loyaltyProgram, 1e15); 
    mintLoyaltyCards(loyaltyProgram, 50);

    // step 2: transfer loyalty cards; 
    giftLoyaltyCard(loyaltyProgram, 1, loyaltyProgram.getOwner(), address2);
    giftLoyaltyCard(loyaltyProgram, 2, loyaltyProgram.getOwner(), address3); 
    giftLoyaltyCard(loyaltyProgram, 3, loyaltyProgram.getOwner(), address4);
    giftLoyaltyCard(loyaltyProgram, 4, loyaltyProgram.getOwner(), address2);  

    // step 3: transfer loyalty points to cards, through discrete transfers;
    for (uint i = 0; 33 > i; i++) {
        giftLoyaltyPoints(loyaltyProgram, loyaltyProgram.getOwner(), 1, 1450); 
    }
    for (uint i = 0; 23 > i; i++) {
        giftLoyaltyPoints(loyaltyProgram, loyaltyProgram.getOwner(), 2, 1350); 
    }
    for (uint i = 0; 13 > i; i++) {
        giftLoyaltyPoints(loyaltyProgram, loyaltyProgram.getOwner(), 4, 2250); 
    }

    // step 4: select and mint Loyalty Gifts. 
    vm.startBroadcast();
    for (uint i = 0; GIFTS_TO_SELECT.length > i; i++) {
      LoyaltyProgram(loyaltyProgram).addLoyaltyGift(payable(loyaltyGiftsAddress), GIFTS_TO_SELECT[i]); 
    }
    LoyaltyProgram(loyaltyProgram).mintLoyaltyTokens(payable(loyaltyGiftsAddress), TOKENS_TO_MINT, AMOUNT_TOKENS_TO_MINT); 
    vm.stopBroadcast(); 
      
    // step 5: transfer loyalty cards between customers; 
    vm.startBroadcast(privateKey2);
    LoyaltyProgram(loyaltyProgram).safeTransferFrom(address2, address3, 1, 1, "");
    vm.stopBroadcast();

    // step 6: claim loyalty gift by redeeming points 
    // address cardAddress = payable(LoyaltyProgram(loyaltyProgram).getTokenBoundAddress(4)); 
    // uint256 loyaltyGiftId = 4; 
    // uint256 loyaltyPoints = 5000; 
    // uint256 nonceLoyaltyCard = 0; 
    
    // // first make signed request 
    // bytes32 messageHash = keccak256(
    //     abi
    //     .encodePacked(
    //       loyaltyGiftsContract, // loyaltyGiftsAddress, 
    //       loyaltyGiftId, // loyaltyGiftId, -- this one should give a token. 
    //       cardAddress,  // loyaltyCardAddress, 
    //       address2, // customerAddress,
    //       loyaltyPoints, // loyaltyPoints,
    //       nonceLoyaltyCard // s_nonceLoyaltyCard[loyaltyCardAddress]
    //     )).toEthSignedMessageHash();

    // (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey2, messageHash); 
    // bytes memory signature = abi.encodePacked(r, s, v); 
    
    // vm.startBroadcast(); 
    // // then call function at loyaltyProgram to mint 
    // LoyaltyProgram(loyaltyProgram).claimLoyaltyGift(
    //   address(loyaltyGiftsContract), // loyaltyGiftsAddress, 
    //   loyaltyGiftId, // loyaltyGiftId, -- this one should give a token. 
    //   cardAddress,  // loyaltyCardAddress, 
    //   address2, // customerAddress,
    //   loyaltyPoints, // loyaltyPoints,
    //   signature // bytes memory signature
    // ); 
    // vm.stopBroadcast();
    }

    function mintLoyaltyPoints(LoyaltyProgram lpInstance, uint256 numberOfPoints) public {
      vm.startBroadcast();
      LoyaltyProgram(lpInstance).mintLoyaltyPoints(numberOfPoints);
      vm.stopBroadcast();
    }

    function mintLoyaltyCards(LoyaltyProgram lpInstance, uint256 numberOfCards) public {
      vm.startBroadcast();
      LoyaltyProgram(lpInstance).mintLoyaltyCards(numberOfCards);
      // for (uint i = 0; numberOfCards > i; i++) {
      //   address cardAddress = payable(LoyaltyProgram(lpInstance).getTokenBoundAddress(i)); 
      //   (bool sent, bytes memory data) = cardAddress.call{value: 1000000000000000000}("");
      //   require(sent, "failed to send ether"); 
      // }
      vm.stopBroadcast();
    }

    function giftLoyaltyCard(LoyaltyProgram lpInstance, uint256 loyaltyCardId, address from, address to) public {
      vm.startBroadcast();
      LoyaltyProgram(lpInstance).safeTransferFrom(from, to, loyaltyCardId, 1, "");
      vm.stopBroadcast();
    }

    function giftLoyaltyPoints(LoyaltyProgram lpInstance, address from, uint256 loyaltyCardId, uint256 numberOfPoints) public {
      vm.startBroadcast();
      address to = LoyaltyProgram(lpInstance).getTokenBoundAddress(loyaltyCardId); 
      LoyaltyProgram(lpInstance).safeTransferFrom(from, to, 0, numberOfPoints, "");
      vm.stopBroadcast();
    }

    // function addLoyaltyGift(
    //   LoyaltyProgram lpInstance, 
    //   uint256 loyaltyTokenId
    //   ) public {
    //     vm.startBroadcast();
    //     LoyaltyProgram(lpInstance).addLoyaltyGift(loyaltyGiftsContract, loyaltyTokenId);
    //     vm.stopBroadcast();
    // }

    // function mintLoyaltyTokens(
    //   address payable loyaltyGiftAddress, 
    //   uint256[] memory loyaltyGiftIds, 
    //   uint256[] memory numberOfTokens)
    function mintLoyaltyGifts(
      LoyaltyProgram lpInstance, 
      address payable loyaltyGiftAddress, 
      uint256[] memory loyaltyGiftIds, 
      uint256[] memory numberOfTokens
      ) public {
      vm.startBroadcast();
      LoyaltyProgram(lpInstance).mintLoyaltyTokens(loyaltyGiftAddress, loyaltyGiftIds, numberOfTokens);
      vm.stopBroadcast();
    }
    
//     function claimLoyaltyGifts(LoyaltyProgram lpInstance, address payable loyaltyTokenAddress, uint256 numberOfPoints, uint256 loyaltyCardId)  public {
//       uint256 ownerPrivateKey = vm.envUint("DEFAULT_ANVIL_KEY_3");
//       vm.startBroadcast(ownerPrivateKey);
//       LoyaltyProgram(lpInstance).redeemLoyaltyPoints(loyaltyTokenAddress, numberOfPoints, loyaltyCardId);
//       vm.stopBroadcast();
//     }
}

