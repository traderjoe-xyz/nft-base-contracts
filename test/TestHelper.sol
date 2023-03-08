// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

abstract contract TestHelper is Test {
    address payable internal joepegs = payable(makeAddr("joepegs"));
}
