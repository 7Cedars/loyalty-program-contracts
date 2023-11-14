// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC6551Registry} from "../../src/ERC6551Registry.sol";
import {ERC6551Account} from "../../src/ERC6551Account.sol";
import {MockERC1155} from "../mocks/MockERC1155.sol";
import {MockERC6551Account} from "../mocks/MockERC6551Account.sol";
import {IERC6551Account} from "../../src/interfaces/IERC6551Account.sol";

contract AccountTest is Test {
    ERC6551Registry public registry;
    ERC6551Account public implementation;
    MockERC1155 nft = new MockERC1155();

    function setUp() public {
        registry = new ERC6551Registry();
        implementation = new ERC6551Account();
    }

    function testDeploy() public {
        address deployedAccount =
            registry.createAccount(address(implementation), block.chainid, address(0), 0, 3947539732098357, "");

        assertTrue(deployedAccount != address(0));

        address predictedAccount =
            registry.account(address(implementation), block.chainid, address(0), 0, 3947539732098357);

        assertEq(predictedAccount, deployedAccount);
    }

    function testCall() public {
        nft.mint(vm.addr(1), 1, 1);

        address account =
            registry.createAccount(address(implementation), block.chainid, address(nft), 1, 3947539732098357, "");

        assertTrue(account != address(0));

        IERC6551Account accountInstance = IERC6551Account(payable(account));
        (,, uint256 tokenId) = accountInstance.token();

        assertEq(tokenId, 1); // previous Owner function does not work on ERC1155 - ERC 1155 does not have OwnerOf function.

        vm.deal(account, 1 ether);
        vm.prank(vm.addr(1));
        accountInstance.executeCall(payable(vm.addr(2)), 0.5 ether, "");

        assertEq(account.balance, 0.5 ether);
        assertEq(vm.addr(2).balance, 0.5 ether);
        assertEq(accountInstance.nonce(), 1);
    }
}
