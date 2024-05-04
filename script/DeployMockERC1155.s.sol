// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {MockERC1155} from "../test/mocks/MockERC1155.sol";

contract DeployMockERC1155 is Script {
    function run() external returns (IERC1155) {
        vm.startBroadcast();
        IERC1155 mockERC1155 = new MockERC1155();
        vm.stopBroadcast();
        return mockERC1155;
    }
}
