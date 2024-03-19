// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721("MockERC721", "M721") {}

    function testA() public {} // to have foundry ignore this file in coverage report. see £ack https://ethereum.stackexchange.com/questions/155700/force-foundry-to-ignore-contracts-during-a-coverage-report

    function mint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }
}
