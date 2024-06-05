// SPDX-License-Identifier: MIT

// test files builds on original from Standard ERC6511 example. see: ADD LINK. -- tokenbound website?
// This should include added features of ERC6551BespokeAccount
pragma solidity 0.8.24;

import "forge-std/Test.sol";

import {LoyaltyCard6551Account} from "../../src/LoyaltyCard6551Account.sol";
import {ERC6551Registry} from "@erc6551/ERC6551Registry.sol"; 
import "../../src/interfaces/IERC6551Account.sol";
import "../../src/interfaces/IERC6551Executable.sol";
import "../mocks/MockERC721.sol";
import "../mocks/MockERC1155.sol";
import "../mocks/MockERC6551Account.sol";

contract AccountTest is Test {
    ERC6551Registry public registry;
    LoyaltyCard6551Account public implementation;
    MockERC721 nft = new MockERC721();
    MockERC1155 nft1155 = new MockERC1155();

    function setUp() public {
        registry = new ERC6551Registry();
        implementation = new LoyaltyCard6551Account();
    }

    function testDeploy() public {
        address deployedAccount =
            registry.createAccount(address(implementation), 0, block.chainid, address(0), 0);

        assertTrue(deployedAccount != address(0));

        address predictedAccount =
            registry.account(address(implementation), 0, block.chainid, address(0), 0);

        assertEq(predictedAccount, deployedAccount);
    }

    function testCall() public {
        nft.mint(vm.addr(1), 1);

        address account =
            registry.createAccount(address(implementation), 0, block.chainid, address(nft), 1);

        assertTrue(account != address(0));

        IERC6551Account accountInstance = IERC6551Account(payable(account));
        IERC6551Executable executableAccountInstance = IERC6551Executable(account);

        assertEq(
            accountInstance.isValidSigner(vm.addr(1), ""), IERC6551Account.isValidSigner.selector
        );

        vm.deal(account, 1 ether);

        vm.prank(vm.addr(1));
        executableAccountInstance.execute(payable(vm.addr(2)), 0.5 ether, "", 0);

        assertEq(account.balance, 0.5 ether);
        assertEq(vm.addr(2).balance, 0.5 ether);
        assertEq(accountInstance.state(), 1);
    }
    
}
