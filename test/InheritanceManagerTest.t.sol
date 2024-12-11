//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {InheritanceManager} from "../src/InheritanceManager.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract InheritanceManagerTest is Test {
    InheritanceManager im;
    ERC20Mock usdc;
    ERC20Mock weth;

    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");

    function setUp() public {
        vm.prank(owner);
        im = new InheritanceManager();
        usdc = new ERC20Mock();
        weth = new ERC20Mock();
    }

    function test_sendERC20FromOwner() public {
        usdc.mint(address(im), 10e18);
        weth.mint(address(im), 10e18);
        vm.startPrank(owner);
        im.sendERC20(address(weth), 1e18, user1);
        assertEq(weth.balanceOf(address(im)), 9e18);
        assertEq(weth.balanceOf(user1), 1e18);
        vm.stopPrank();
    }

    function test_sendERC20FromUserFail() public {
        usdc.mint(address(im), 10e18);
        weth.mint(address(im), 10e18);
        vm.startPrank(user1);
        vm.expectRevert();
        im.sendERC20(address(weth), 1e18, user1);
        assertEq(weth.balanceOf(address(im)), 10e18);
        vm.stopPrank();
    }

    function test_sendERC20FromOwnerDeadlineUpdate() public {
        uint256 deadline = im.getDeadline();
        uint256 expectedDeadline = 1 + 90 days;
        usdc.mint(address(im), 10e18);
        weth.mint(address(im), 10e18);
        vm.warp(10);
        vm.startPrank(owner);
        im.sendERC20(address(weth), 1e18, user1);
        assertEq(weth.balanceOf(address(im)), 9e18);
        assertEq(weth.balanceOf(user1), 1e18);
        deadline = im.getDeadline();
        expectedDeadline = 10 + 90 days;
        assertEq(deadline, expectedDeadline);
        vm.stopPrank();
    }

    function test_sendEtherFromOwner() public {
        vm.deal(address(im), 10e18);
        vm.startPrank(owner);
        im.sendETH(1e18, user1);
        assertEq(address(im).balance, 9e18);
        assertEq(user1.balance, 1e18);
        vm.stopPrank();
    }

    function test_sendEtherFromUserFail() public {
        vm.deal(address(im), 10e18);
        vm.startPrank(user1);
        vm.expectRevert();
        im.sendETH(1e18, owner);
        assertEq(address(im).balance, 10e18);
        vm.stopPrank();
    }

    function test_sendEtherFromOwnerDeadlineUpdate() public {
        uint256 deadline = im.getDeadline();
        uint256 expectedDeadline = 1 + 90 days;
        vm.deal(address(im), 10e18);
        vm.warp(10);
        vm.startPrank(owner);
        im.sendETH(1e18, user1);
        assertEq(address(im).balance, 9e18);
        assertEq(user1.balance, 1e18);
        deadline = im.getDeadline();
        expectedDeadline = 10 + 90 days;
        assertEq(deadline, expectedDeadline);
        vm.stopPrank();
    }
}
