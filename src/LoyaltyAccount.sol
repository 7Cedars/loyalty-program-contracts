// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LoyaltyAccount is ERC20 {
    constructor(uint256 initialSupply) ERC20("LoyaltyPoints", "LPX") {
        _mint(msg.sender, initialSupply);
    }
}

