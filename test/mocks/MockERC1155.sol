// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    
    constructor() ERC1155("") {}

    function testA() public {} // to have foundry ignore this file in coverage report. see £ack https://ethereum.stackexchange.com/questions/155700/force-foundry-to-ignore-contracts-during-a-coverage-report

    function mint(address to, uint256 tokenId, uint256 amount) external {
        _mint(to, tokenId, amount, "");
    }
}
