// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {ERC6551Account} from "../src/ERC6551Account.sol";
import {LoyaltyProgram} from "../src/LoyaltyProgram.sol";
import {LoyaltyGift} from "../src/LoyaltyGift.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLoyaltyProgram is Script {
    LoyaltyProgram loyaltyProgram;

    // NB: If I need a helper config, see helperConfig.s.sol + learning/foundry-fund-me-f23
    function run() external returns (LoyaltyProgram) {
        vm.startBroadcast();
        loyaltyProgram = new LoyaltyProgram("https://ipfs.io/ipfs/QmeZSxMGSxEAepscJamhJQ56cCfBhU91D1imPtRxX3VUSZ.json");
        vm.stopBroadcast();
        return (loyaltyProgram);
    }
}

contract DeployLoyaltyProgramA is Script {
    LoyaltyProgram loyaltyProgramA;
    ERC6551Account ercAccount;
    
    address[] DEFAULT_ANVIL_ACCOUNTS = [
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, 
        0x90F79bf6EB2c4f870365E785982E1f101E93b906, 
        0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
        ]; 

    address[] DEFAULT_ANVIL_LOYALTY_TOKENS = [
        0xbdEd0D2bf404bdcBa897a74E6657f1f12e5C6fb6, 
        0x2910E325cf29dd912E3476B61ef12F49cb931096,
        0xA7918D253764E42d60C3ce2010a34d5a1e7C1398
        ]; 

    function run() external {
        uint numberOfTransactions1 = 15; 
        uint numberOfTransactions2 = 25; 
        uint numberOfTransactions3 = 30; 
        
        vm.startBroadcast();
        // step 1: setup program
        loyaltyProgramA = new LoyaltyProgram("https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmUkn86g76kMDKsch1Lneckc9Bp6c8viU2MbFojgxNvTts");
        // address oneCoffeeFor2500 = DevOpsTools.get_most_recent_deployment("OneCoffeeFor2500", block.chainid);
        // address contractAddress = DevOpsTools.get_most_recent_deployment("IER", block.chainid);
        // LoyaltyProgram loyaltyProgramA = LoyaltyProgram(payable(contractAddress));

        vm.stopBroadcast();

        // // step 2: mint loyalty points and cards; 
        mintLoyaltyPoints(loyaltyProgramA, 1e15); 
        mintLoyaltyCards(loyaltyProgramA, 50);
        addLoyaltyGiftContract(loyaltyProgramA, payable(DEFAULT_ANVIL_LOYALTY_TOKENS[0]));
        mintLoyaltyGifts(loyaltyProgramA, payable(DEFAULT_ANVIL_LOYALTY_TOKENS[0]), 50); 

        // // step 3: transfer loyalty cards; 
        giftLoyaltyCard(loyaltyProgramA, 1, loyaltyProgramA.getOwner(), DEFAULT_ANVIL_ACCOUNTS[2]);
        giftLoyaltyCard(loyaltyProgramA, 2, loyaltyProgramA.getOwner(), DEFAULT_ANVIL_ACCOUNTS[3]); 
        giftLoyaltyCard(loyaltyProgramA, 3, loyaltyProgramA.getOwner(), DEFAULT_ANVIL_ACCOUNTS[4]);
        giftLoyaltyCard(loyaltyProgramA, 4, loyaltyProgramA.getOwner(), DEFAULT_ANVIL_ACCOUNTS[2]);  

        // // step 4: transfer loyalty points to cards, through discrete transfers;
        for (uint i = 0; numberOfTransactions1 > i; i++) {
            giftLoyaltyPoints(loyaltyProgramA, loyaltyProgramA.getOwner(), 1, 450); 
        }
        for (uint i = 0; numberOfTransactions2 > i; i++) {
            giftLoyaltyPoints(loyaltyProgramA, loyaltyProgramA.getOwner(), 2, 350); 
        }
        for (uint i = 0; numberOfTransactions3 > i; i++) {
            giftLoyaltyPoints(loyaltyProgramA, loyaltyProgramA.getOwner(), 4, 1250); 
        }
        
        // step 5: transfer loyalty cards between customers; 
        uint256 ownerPrivateKey = vm.envUint("DEFAULT_ANVIL_KEY_2");
        vm.startBroadcast(ownerPrivateKey);
        LoyaltyProgram(loyaltyProgramA).safeTransferFrom(DEFAULT_ANVIL_ACCOUNTS[2], DEFAULT_ANVIL_ACCOUNTS[3], 1, 1, "");
        vm.stopBroadcast();

        // step 6: claim loyalty gift by redeeming points 
        address cardAddress = payable(LoyaltyProgram(loyaltyProgramA).getTokenBoundAddress(4)); 

        vm.startBroadcast(ownerPrivateKey);
        // claimLoyaltyGifts(loyaltyProgramA, payable(DEFAULT_ANVIL_LOYALTY_TOKENS[0]), 5002, 2);
        
        ERC6551Account(payable(cardAddress)).executeCall(
          payable(loyaltyProgramA),
          0,
          abi.encodeCall(
              LoyaltyProgram.redeemLoyaltyPoints, 
              (payable(DEFAULT_ANVIL_LOYALTY_TOKENS[0]), 
              5002, 
              4))
              ); 
        vm.stopBroadcast();
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

    function addLoyaltyGiftContract(LoyaltyProgram lpInstance, address payable loyaltyTokenAddress) public {
      vm.startBroadcast();
      LoyaltyProgram(lpInstance).addLoyaltyGiftContract(loyaltyTokenAddress);
      vm.stopBroadcast();
    }

    function mintLoyaltyGifts(LoyaltyProgram lpInstance, address payable loyaltyTokenAddress, uint256 numberOfTokens) public {
      // uint256 ownerPrivateKey = vm.envUint("DEFAULT_ANVIL_KEY_2");
      vm.startBroadcast();
      LoyaltyProgram(lpInstance).mintLoyaltyGifts(loyaltyTokenAddress, numberOfTokens);
      vm.stopBroadcast();
    }
    
//     function claimLoyaltyGifts(LoyaltyProgram lpInstance, address payable loyaltyTokenAddress, uint256 numberOfPoints, uint256 loyaltyCardId)  public {
//       uint256 ownerPrivateKey = vm.envUint("DEFAULT_ANVIL_KEY_3");
//       vm.startBroadcast(ownerPrivateKey);
//       LoyaltyProgram(lpInstance).redeemLoyaltyPoints(loyaltyTokenAddress, numberOfPoints, loyaltyCardId);
//       vm.stopBroadcast();
//     }
}


contract DeployLoyaltyProgramB is Script {
    LoyaltyProgram loyaltyProgramB;

     address[] DEFAULT_ANVIL_LOYALTY_TOKENS = [
      0xbdEd0D2bf404bdcBa897a74E6657f1f12e5C6fb6, 
      0x2910E325cf29dd912E3476B61ef12F49cb931096,
      0xA7918D253764E42d60C3ce2010a34d5a1e7C1398
    ]; 

    function run() external {        
        vm.startBroadcast();
        // step 1: setup program
        loyaltyProgramB = new LoyaltyProgram("https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmTJCpvkE2gU8E6Ypz9yybJaQ2yLXNh5ayYPfmHBnZuJyw");
        vm.stopBroadcast();

        // // step 2: mint loyalty points and cards; 
        mintLoyaltyPoints(loyaltyProgramB, 5000); 
        mintLoyaltyCards(loyaltyProgramB, 1); 
        addLoyaltyGiftContract(loyaltyProgramB, payable(DEFAULT_ANVIL_LOYALTY_TOKENS[1]));  
    }

    function mintLoyaltyPoints(LoyaltyProgram lpInstance, uint256 numberOfPoints) public {
      vm.startBroadcast();
      LoyaltyProgram(lpInstance).mintLoyaltyPoints(numberOfPoints);
      vm.stopBroadcast();
    }

    function mintLoyaltyCards(LoyaltyProgram lpInstance, uint256 numberOfCards) public {
      vm.startBroadcast();
      LoyaltyProgram(lpInstance).mintLoyaltyCards(numberOfCards);
      vm.stopBroadcast();
    }

    function addLoyaltyGiftContract(LoyaltyProgram lpInstance, address payable loyaltyTokenAddress) public {
      vm.startBroadcast();
      LoyaltyProgram(lpInstance).addLoyaltyGiftContract(loyaltyTokenAddress);
      vm.stopBroadcast();
    }
}

contract DeployLoyaltyProgramC is Script {
    LoyaltyProgram loyaltyProgramC;

    function run() external {        
        vm.startBroadcast();
        // step 1: setup program
        loyaltyProgramC = new LoyaltyProgram("https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/QmYDXgbSgF8HnHaqu28Gr4afNqz6onDaB5bmrCKNNdMVPJ");
        vm.stopBroadcast();

        // // step 2: mint loyalty points and cards; 
        mintLoyaltyPoints(loyaltyProgramC, 15000); 
        mintLoyaltyCards(loyaltyProgramC, 10); 
    }

    function mintLoyaltyPoints(LoyaltyProgram lpInstance, uint256 numberOfPoints) public {
      vm.startBroadcast();
      LoyaltyProgram(lpInstance).mintLoyaltyPoints(numberOfPoints);
      vm.stopBroadcast();
    }

    function mintLoyaltyCards(LoyaltyProgram lpInstance, uint256 numberOfCards) public {
      vm.startBroadcast();
      LoyaltyProgram(lpInstance).mintLoyaltyCards(numberOfCards);
      vm.stopBroadcast();
    }
}
