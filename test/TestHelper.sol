// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";

abstract contract TestHelper is Test {
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
}
