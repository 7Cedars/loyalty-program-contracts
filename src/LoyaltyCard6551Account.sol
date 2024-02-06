// SPDX-License-Identifier: UNLICENSED
// NB! I MADE CHANGE TO get check of token ownership in 1155 (instead of 721) assets.
// See if I can propose change in contract?

pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC6551Account} from "./interfaces/IERC6551Account.sol";
import {ERC6551AccountLib} from "./lib/ERC6551AccountLib.sol";

// NB! this is an EXPANDED VERSION OF the standard ERC6551Account! should make that clear..
// But do not want to get in trouble with registry...
contract LoyaltyCard6551Account is IERC165, IERC1271, IERC6551Account, IERC1155Receiver {
    uint256 public nonce;

    receive() external payable {}

    function executeCall(
        address to, // this becomes the msg.sender? should that not be 'from??'
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory result) {
        require(owner1155() == true, "Not tba owner");

        ++nonce;

        emit TransactionExecuted(to, value, data);

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function token() external view returns (uint256, address, uint256) {
        return ERC6551AccountLib.token();
    }

    // this function will not work on 1155.
    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this.token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    // see https://forum.openzeppelin.com/t/erc1155-check-if-token-owner/8503/2
    function owner1155() public view returns (bool) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this.token();
        if (chainId != block.chainid) return false;
        if (IERC1155(tokenContract).balanceOf(msg.sender, tokenId) == 0) return false;
        return true;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC6551Account).interfaceId);
    }

    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
