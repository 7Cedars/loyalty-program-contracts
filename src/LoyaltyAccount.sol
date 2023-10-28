// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LoyaltyAccount is ERC20 {

  address private s_owner; 


  constructor(uint256 initialSupply) ERC20("LoyaltyPoints", "LPX") {
      s_owner = msg.sender; 
      _mint(msg.sender, initialSupply);
    }

  /* Getter functions */

  function getOwner() external view returns (address) {
    return s_owner; 
  } 
}




