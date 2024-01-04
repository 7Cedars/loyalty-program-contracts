// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {LoyaltyProgram} from "../src/LoyaltyProgram.sol";
import {OneCoffeeFor2500} from "../src/PointsForLoyaltyTokens.sol";



contract DeployLoyaltyProgram is Script {
    LoyaltyProgram loyaltyProgramA;
    LoyaltyProgram loyaltyProgramB;
  
    address[] DEFAULT_ANVIL_ACCOUNTS = [
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, 
        0x90F79bf6EB2c4f870365E785982E1f101E93b906, 
        0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
        0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc,
        0x976EA74026E726554dB657fA54763abd0C3a0aa9
        ]; 

    function run() external {
        uint numberOfTransactions1 = 15; 
        uint numberOfTransactions2 = 25; 
        uint numberOfTransactions3 = 30; 
        
        vm.startBroadcast();
        // step 1: setup program
        loyaltyProgramA = new LoyaltyProgram("https://ipfs.io/ipfs/QmeZSxMGSxEAepscJamhJQ56cCfBhU91D1imPtRxX3VUSZ.json");
        loyaltyProgramB = new LoyaltyProgram("https://ipfs.io/ipfs/QmS5tnFso24nY1YavCyackx4ms34wShhLam7qM1rEfDXpC.json");
        vm.stopBroadcast();

        // // step 2: mint loyalty points and cards; 
        mintLoyaltyPoints(loyaltyProgramA, 1e15); 
        mintLoyaltyCards(loyaltyProgramA, 50); 
        mintLoyaltyPoints(loyaltyProgramA, 5000); 
        mintLoyaltyCards(loyaltyProgramA, 1); 

        // step 3: transfer loyalty cards; 
        transferLoyaltyCard(loyaltyProgramA, 1, loyaltyProgramA.getOwner(), DEFAULT_ANVIL_ACCOUNTS[2]);
        transferLoyaltyCard(loyaltyProgramA, 2, loyaltyProgramA.getOwner(), DEFAULT_ANVIL_ACCOUNTS[3]); 
        transferLoyaltyCard(loyaltyProgramA, 3, loyaltyProgramA.getOwner(), DEFAULT_ANVIL_ACCOUNTS[4]);
        transferLoyaltyCard(loyaltyProgramA, 4, loyaltyProgramA.getOwner(), DEFAULT_ANVIL_ACCOUNTS[2]);  

        // step 4: transfer loyalty points to cards, through discrete transfers;
        for (uint i = 0; numberOfTransactions1 > i; i++) {
            transferLoyaltyPoints(loyaltyProgramA, loyaltyProgramA.getOwner(), 1, 450); 
        }
        for (uint i = 0; numberOfTransactions2 > i; i++) {
            transferLoyaltyPoints(loyaltyProgramA, loyaltyProgramA.getOwner(), 2, 350); 
        }
        for (uint i = 0; numberOfTransactions3 > i; i++) {
            transferLoyaltyPoints(loyaltyProgramA, loyaltyProgramA.getOwner(), 3, 250); 
        }

        // step 5: transfer loyalty cards between customers; 
        transferLoyaltyCard(loyaltyProgramA, 1, DEFAULT_ANVIL_ACCOUNTS[2], DEFAULT_ANVIL_ACCOUNTS[3]);
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

    function transferLoyaltyCard(LoyaltyProgram lpInstance, uint256 loyaltyCardId, address from, address to) public {
      vm.startBroadcast();
      LoyaltyProgram(lpInstance).safeTransferFrom(from, to, loyaltyCardId, 1, "");
      vm.stopBroadcast();
    }

    function transferLoyaltyPoints(LoyaltyProgram lpInstance, address from, uint256 loyaltyCardId, uint256 numberOfPoints) public {
      vm.startBroadcast();
      address to = LoyaltyProgram(lpInstance).getTokenBoundAddress(loyaltyCardId); 
      LoyaltyProgram(lpInstance).safeTransferFrom(from, to, 0, numberOfPoints, "");
      vm.stopBroadcast();
    }

}

contract TransferPoints is Script {

  function run() external {
    uint numberOfTransactions1 = 7;
    address contractAddress = DevOpsTools.get_most_recent_deployment("LoyaltyProgram", block.chainid);
    LoyaltyProgram loyaltyProgramA = LoyaltyProgram(payable(contractAddress));


    for (uint i = 0; numberOfTransactions1 > i; i++) {
        transferLoyaltyPoints(loyaltyProgramA, loyaltyProgramA.getOwner(), 1, 450); 
    }
  }

  function transferLoyaltyPoints(LoyaltyProgram lpInstance, address from, uint256 loyaltyCardId, uint256 numberOfPoints) public {
    vm.startBroadcast();
    address to = LoyaltyProgram(lpInstance).getTokenBoundAddress(loyaltyCardId); 
    LoyaltyProgram(lpInstance).safeTransferFrom(from, to, 0, numberOfPoints, "");
    vm.stopBroadcast();
  }
  
}
