// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {LoyaltyProgram} from "../src/LoyaltyProgram.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

import {ERC6551BespokeAccount} from "../src/mocks/ERC6551BespokeAccount.sol";
import {MockLoyaltyGifts} from "../src/mocks/MockLoyaltyGifts.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract DeployLoyaltyProgram is Script {
    LoyaltyProgram loyaltyProgram;

    // NB: If I need a helper config, see helperConfig.s.sol + learning/foundry-fund-me-f23
    function run() external returns (LoyaltyProgram, HelperConfig) {
       HelperConfig helperConfig = new HelperConfig(); 

        ( string memory uri,
          ,
          ,
          address erc65511Registry, 
          address payable erc65511Implementation, 

        ) = helperConfig.activeNetworkConfig();  

      vm.startBroadcast();
      loyaltyProgram = new LoyaltyProgram(
        uri, 
        erc65511Registry,
        erc65511Implementation
        );
      vm.stopBroadcast();

      return (loyaltyProgram, helperConfig);
    }    
}

// contract Interactions is Script {
//   // uint256[] public TOKENISED = [0, 0, 0, 1, 1, 1]; // 0 == false, 1 == true.  
//   uint256[] public TOKENIDS = [0, 0, 0, 1, 1, 1]; // 0 == false, 1 == true.  
//   uint256[] public tokenValues = [0, 0, 0, 1, 1, 1]; // 0 == false, 1 == true.  
//   // string public URI = "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmWxDUUMwKuKpufkYpU4QVgQLR1eHruGxKiKheGpFktb2w/{id}"; 

//   using ECDSA for bytes32;
//   using MessageHashUtils for bytes32;

//   LoyaltyProgram loyaltyProgram;
//   MockLoyaltyGifts loyaltyGiftsContract; 
//   HelperConfig helperConfig; 
//   ERC6551Account ercAccount;
//   address internal customerOne;
//   address internal customerTwo; 
//   address internal customerThree;
  
//   uint256 privateKey0 = vm.envUint("DEFAULT_ANVIL_KEY_0");
//   address address0 = vm.addr(privateKey0); 
//   uint256 privateKey1 = vm.envUint("DEFAULT_ANVIL_KEY_1");
//   address address1 = vm.addr(privateKey1); 
//   uint256 privateKey2 = vm.envUint("DEFAULT_ANVIL_KEY_2");
//   address address2 = vm.addr(privateKey2); 
//   uint256 privateKey3 = vm.envUint("DEFAULT_ANVIL_KEY_3");
//   address address3 = vm.addr(privateKey3); 
//   uint256 privateKey4 = vm.envUint("DEFAULT_ANVIL_KEY_4");
//   address address4 = vm.addr(privateKey4); 

//   function run() external {
//     helperConfig = new HelperConfig(); 

//     vm.startBroadcast();
//     loyaltyProgram = new LoyaltyProgram("https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmTJCpvkE2gU8E6Ypz9yybJaQ2yLXNh5ayYPfmHBnZuJyw");
//     loyaltyGiftsContract = new MockLoyaltyGifts();
//     vm.stopBroadcast();

//     // // step 2: mint loyalty points and cards; 
//     mintLoyaltyPoints(loyaltyProgram, 1e15); 
//     mintLoyaltyCards(loyaltyProgram, 50);
//     for (uint i = 0; TOKENIDS.length > i; i++) { 
//       addLoyaltyGift(loyaltyProgram, i); 
//       }
//     mintLoyaltyGifts(loyaltyProgram, payable(loyaltyGiftsContract), TOKENIDS, tokenValues);

//     // // step 3: transfer loyalty cards; 
//     giftLoyaltyCard(loyaltyProgram, 1, loyaltyProgram.getOwner(), address2);
//     giftLoyaltyCard(loyaltyProgram, 2, loyaltyProgram.getOwner(), address3); 
//     giftLoyaltyCard(loyaltyProgram, 3, loyaltyProgram.getOwner(), address4);
//     giftLoyaltyCard(loyaltyProgram, 4, loyaltyProgram.getOwner(), address2);  

//       // // step 4: transfer loyalty points to cards, through discrete transfers;
//       for (uint i = 0; 33 > i; i++) {
//           giftLoyaltyPoints(loyaltyProgram, loyaltyProgram.getOwner(), 1, 450); 
//       }
//       for (uint i = 0; 23 > i; i++) {
//           giftLoyaltyPoints(loyaltyProgram, loyaltyProgram.getOwner(), 2, 350); 
//       }
//       for (uint i = 0; 13 > i; i++) {
//           giftLoyaltyPoints(loyaltyProgram, loyaltyProgram.getOwner(), 4, 1250); 
//       }
      
//       // step 5: transfer loyalty cards between customers; 
//       vm.startBroadcast(privateKey2);
//       LoyaltyProgram(loyaltyProgram).safeTransferFrom(address2, address3, 1, 1, "");
//       vm.stopBroadcast();

//       // step 6: claim loyalty gift by redeeming points 
//       address cardAddress = payable(LoyaltyProgram(loyaltyProgram).getTokenBoundAddress(4)); 
//       uint256 loyaltyGiftId = 4; 
//       uint256 loyaltyPoints = 5000; 
//       uint256 nonceLoyaltyCard = 0; 
      
//       // first make signed request 
//       bytes32 messageHash = keccak256(
//           abi
//           .encodePacked(
//             loyaltyGiftsContract, // loyaltyGiftsAddress, 
//             loyaltyGiftId, // loyaltyGiftId, -- this one should give a token. 
//             cardAddress,  // loyaltyCardAddress, 
//             address2, // customerAddress,
//             loyaltyPoints, // loyaltyPoints,
//             nonceLoyaltyCard // s_nonceLoyaltyCard[loyaltyCardAddress]
//           )).toEthSignedMessageHash();

//       (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey2, messageHash); 
//       bytes memory signature = abi.encodePacked(r, s, v); 
      
//       vm.startBroadcast(); 
//       // then call function at loyaltyProgram to mint 
//       LoyaltyProgram(loyaltyProgram).claimLoyaltyGift(
//         address(loyaltyGiftsContract), // loyaltyGiftsAddress, 
//         loyaltyGiftId, // loyaltyGiftId, -- this one should give a token. 
//         cardAddress,  // loyaltyCardAddress, 
//         address2, // customerAddress,
//         loyaltyPoints, // loyaltyPoints,
//         signature // bytes memory signature
//       ); 
//       vm.stopBroadcast();
//     }

//     function mintLoyaltyPoints(LoyaltyProgram lpInstance, uint256 numberOfPoints) public {
//       vm.startBroadcast();
//       LoyaltyProgram(lpInstance).mintLoyaltyPoints(numberOfPoints);
//       vm.stopBroadcast();
//     }

//     function mintLoyaltyCards(LoyaltyProgram lpInstance, uint256 numberOfCards) public {
//       vm.startBroadcast();
//       LoyaltyProgram(lpInstance).mintLoyaltyCards(numberOfCards);
//       // for (uint i = 0; numberOfCards > i; i++) {
//       //   address cardAddress = payable(LoyaltyProgram(lpInstance).getTokenBoundAddress(i)); 
//       //   (bool sent, bytes memory data) = cardAddress.call{value: 1000000000000000000}("");
//       //   require(sent, "failed to send ether"); 
//       // }
//       vm.stopBroadcast();
//     }

//     function giftLoyaltyCard(LoyaltyProgram lpInstance, uint256 loyaltyCardId, address from, address to) public {
//       vm.startBroadcast();
//       LoyaltyProgram(lpInstance).safeTransferFrom(from, to, loyaltyCardId, 1, "");
//       vm.stopBroadcast();
//     }

//     function giftLoyaltyPoints(LoyaltyProgram lpInstance, address from, uint256 loyaltyCardId, uint256 numberOfPoints) public {
//       vm.startBroadcast();
//       address to = LoyaltyProgram(lpInstance).getTokenBoundAddress(loyaltyCardId); 
//       LoyaltyProgram(lpInstance).safeTransferFrom(from, to, 0, numberOfPoints, "");
//       vm.stopBroadcast();
//     }

//     function addLoyaltyGift(
//       LoyaltyProgram lpInstance, 
//       uint256 loyaltyTokenId
//       ) public {
//         vm.startBroadcast();
//         LoyaltyProgram(lpInstance).addLoyaltyGift(payable(loyaltyGiftsContract), loyaltyTokenId);
//         vm.stopBroadcast();
//     }

//     // function mintLoyaltyTokens(
//     //   address payable loyaltyGiftAddress, 
//     //   uint256[] memory loyaltyGiftIds, 
//     //   uint256[] memory numberOfTokens)
//     function mintLoyaltyGifts(
//       LoyaltyProgram lpInstance, 
//       address payable loyaltyGiftAddress, 
//       uint256[] memory loyaltyGiftIds, 
//       uint256[] memory numberOfTokens
//       ) public {
//       vm.startBroadcast();
//       LoyaltyProgram(lpInstance).mintLoyaltyTokens(loyaltyGiftAddress, loyaltyGiftIds, numberOfTokens);
//       vm.stopBroadcast();
//     }
    
// //     function claimLoyaltyGifts(LoyaltyProgram lpInstance, address payable loyaltyTokenAddress, uint256 numberOfPoints, uint256 loyaltyCardId)  public {
// //       uint256 ownerPrivateKey = vm.envUint("DEFAULT_ANVIL_KEY_3");
// //       vm.startBroadcast(ownerPrivateKey);
// //       LoyaltyProgram(lpInstance).redeemLoyaltyPoints(loyaltyTokenAddress, numberOfPoints, loyaltyCardId);
// //       vm.stopBroadcast();
// //     }
// }

