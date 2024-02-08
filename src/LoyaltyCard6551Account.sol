// SPDX-License-Identifier: UNLICENSED

/**
 * @dev THIS CONTRACT HAS NOT BEEN AUDITED. WORSE: TESTING IS INCOMPLETE + THERE ARE KNOWN BUGS. DO NOT DEPLOY ON ANYTHING ELSE THAN A TEST NET! 
 * 
 * @title Loyalty Card 6551 Account
 * @author TokenBound, adapted by Seven Cedars for use with ERC1155 contracts.  
 * @notice A bespoke version of ERC6551 AccountV2 (? I think V2 - £todo: check!) from TokenBound. Optimised for ERC-1155. 
 * 
 * @dev Upgrading this account contract to AccountV3 is on the todo list. 
 * 
 */ 

pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC6551Account} from "./interfaces/IERC6551Account.sol";
import {ERC6551AccountLib} from "./lib/ERC6551AccountLib.sol";

/**
 * @notice In this contract everything is same as original, unless stated otherwise. 
 */

contract LoyaltyCard6551Account is IERC165, IERC1271, IERC6551Account, IERC1155Receiver {
    uint256 public nonce;

    receive() external payable {}

    /**
     * @dev the require has been changed to call the internal owner1155 function. 
     */
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

    /**
     * @dev Note that this function does not work for ERC-1155 based contracts, as it does not have an ownerOf function. 
     * This is because in ERC 1155 the non-fungible state of tokens is not absolute (as with ERC-721). 
     * It means that each coin can potentially be minted multiple times, making an absolute ownership of a single token by one address impossible.   
     */
    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this.token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    /**
     * @notice checks if msg.sender owns the ERC 1155 token.
     * 
     * @dev IMPORTANT £security: ERC-1155 tokens can be minted more than once. It means that __multiple__ addresses can be owner of the same token! 
     * This function DOES NOT check for this. The external contract  minting tokens has to ensure that each token can only be minted once!
     * 
     * @dev this is likely the reason that standard TBAs only work with ERC-721 standard.
     * 
     */
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

    /**
     * @dev added onERC1155Received function to make single transfers of ERC1155 tokens to TBA possible.  
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev added onERC1155Received function to make batch transfers of ERC1155 tokens to TBA possible.  
     */
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
