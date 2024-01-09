// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployLoyaltyProgram} from "../../../script/DeployLoyaltyProgram.s.sol";
import {
  DeployLoyaltyToken,
  DeployMultipleLoyaltyTokens
  } from "../../../script/DeployLoyaltyTokens.s.sol";
import {LoyaltyProgram} from "../../../src/LoyaltyProgram.sol" ;
import {LoyaltyToken} from "../../../src/LoyaltyToken.sol" ;

contract ContinueOnRevertHandler is Test {
  DeployLoyaltyProgram deployerLP; 
  DeployLoyaltyToken deployerLT; 
  LoyaltyProgram[] loyaltyPrograms; 
  LoyaltyToken[] loyaltyTokens; 
  ContinueOnRevertHandler handler; 

  constructor(LoyaltyProgram[] memory _loyaltyPrograms, LoyaltyToken[] memory _loyaltyTokens) {
        loyaltyPrograms = _loyaltyPrograms;
        loyaltyTokens = _loyaltyTokens; 
  }

  function mintPointsCardsAndTokens(uint256 seedPoints, uint256 seedCards, uint256 seedToken) public {

    seedPoints = bound(seedPoints, 5000, 50000000);
    seedCards = bound(seedCards, 2, 12);
    seedToken = bound(seedToken, 1, 25);

    for (uint i; i < loyaltyPrograms.length; i++) { 
      vm.startPrank(loyaltyPrograms[i].getOwner()); 
      loyaltyPrograms[i].mintLoyaltyPoints(seedPoints); 
      loyaltyPrograms[i].mintLoyaltyCards(seedCards); 

      for (uint j; j < loyaltyTokens.length; j++) { 
        loyaltyPrograms[i].addLoyaltyTokenContract(payable(address(loyaltyTokens[j]))); 
        loyaltyPrograms[i].mintLoyaltyTokens(payable(address(loyaltyTokens[j])), seedToken);
      }
      vm.stopPrank(); 
    }
  }
}