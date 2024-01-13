// copied from: https://learnweb3.io/lessons/using-metatransaction-to-pay-for-your-users-gas 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract RandomToken is ERC20 {
    constructor() ERC20("", "") {}

    function freeMint(uint amount) public {
        _mint(msg.sender, amount);
    }
}

contract TokenSender {

    using MessageHashUtils for bytes32;
    using ECDSA for bytes32;

    // New mapping
    mapping(bytes32 => bool) executed;

    // Add the nonce parameter here
    function transfer(address sender, uint amount, address recipient, address tokenContract, uint nonce, bytes memory signature) public {
        // Pass ahead the nonce
        bytes32 messageHash = getHash(sender, amount, recipient, tokenContract, nonce);
        bytes32 signedMessageHash = messageHash.toEthSignedMessageHash();

        // Require that this signature hasn't already been executed
        require(!executed[signedMessageHash], "Already executed!");

        address signer = signedMessageHash.recover(signature);

        require(signer == sender, "Signature does not come from sender");

        // Mark this signature as having been executed now
        executed[signedMessageHash] = true;
        bool sent = ERC20(tokenContract).transferFrom(sender, recipient, amount); // NB: NOT safeTransferFrom! 
        require(sent, "Transfer failed");
    }

    // Add the nonce parameter here
    function getHash(address sender, uint amount, address recipient, address tokenContract, uint nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, amount, recipient, tokenContract, nonce));
    }
}