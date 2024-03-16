// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { SimpleOperations } from "../src/SimpleOperations.sol";

contract SimpleOperationsTest is PRBTest, StdCheats {
    SimpleOperations internal so;

    function setUp() public virtual {
        so = new SimpleOperations();       
    }

    function test_1() external {
        assertEq(so.calculateAverage(2,4), 3);
        assertEq(so.calculateAverage(15,17), 16);
        assertEq(so.calculateAverage(9, 10), 9);
        assertEq(so.calculateAverage(2**256 - 2, 2**256 - 3), 2**256 - 3);


        assertEq(so.getBit(10, 2), 1);
        assertEq(so.getBit(10, 3), 0);
        vm.expectRevert();
        so.getBit(10, 5);
    }

    function test_4() external {

        vm.expectRevert();
        so.getBit(5, 0);

        assertEq(so.getBit(4, 1), 0);
        assertEq(so.getBit(5, 3), 1);
        assertEq(so.getBit(10000000000,10), 0);

        vm.expectRevert();
        so.getBit(5, 4);
        assertEq(so.getBit(10000000000,11), 1);

        vm.expectRevert();
        so.getBit(0, 1);
    }
}
