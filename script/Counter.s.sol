// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract CounterScript is Script {
    Counter public counter;

    function setUp() public {}

    function run() public {
        uint256 privateKey1 = vm.envUint("PRIVATE_KEY_1");
        uint256 privateKey2 = vm.envUint("PRIVATE_KEY_2");
        vm.startBroadcast();

        counter = new Counter();

        vm.stopBroadcast();
    }
}
