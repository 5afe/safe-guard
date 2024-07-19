// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SafeGuard} from "../src/SafeGuard.sol";

contract SafeGuardTest is Test {
    SafeGuard public guard;

    function setUp() public {
        guard = new SafeGuard();
    }

    function test_Nothing() public {}
}
