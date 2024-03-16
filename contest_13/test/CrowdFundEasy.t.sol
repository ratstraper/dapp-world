// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { CrowdFundEasy } from "../src/CrowdFundEasy.sol";
import { MyToken } from "../src/MyToken.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


contract CrowdFundEasyTest is PRBTest, StdCheats {
    CrowdFundEasy internal fund;
    MyToken internal token;

    address owner = address(this);
    address user1 = vm.addr(1);
    address user2 = vm.addr(2);
    address user3 = vm.addr(3);
    address user4 = vm.addr(4);
    address user5 = vm.addr(5);
    address user6 = vm.addr(6);
    address user7 = vm.addr(7);
    address user8 = vm.addr(8);
    address user9 = vm.addr(9);

    receive() external payable {}
    fallback() external payable {}

    function setUp() public virtual {
        token = new MyToken("Token", "TKN", 5);
        fund = new CrowdFundEasy(address(token));

        vm.warp(1641000000);
        vm.deal(owner, 10 ether);
        vm.deal(user1, 10 ether);         
        // token.mint(user1, 10000);
        // token.mint(user2, 10000);
        // token.mint(user3, 10000);
        // token.mint(user4, 10000);
        // token.mint(user5, 10000);
        // token.mint(user6, 10000);  
        // token.mint(user7, 10000);  
        // token.mint(user8, 10000);  
        // token.mint(user9, 10000);        
    }

    function test_1() external {
        uint256 remainingTime;
        uint256 goal;
        uint256 totalFunds;
        vm.startPrank(owner);
        token.mint(user1, 100000);
        token.mint(user2, 100000);
        token.mint(user3, 100000);
        token.mint(user4, 100000);
        vm.stopPrank();

        vm.prank(user1);
        token.approve(address(fund), 100000);

        vm.prank(user2);
        token.approve(address(fund), 100000);

        vm.prank(user3);
        token.approve(address(fund), 100000);

        vm.prank(user4);
        token.approve(address(fund), 100000);

        vm.startPrank(user1);
        fund.createCampaign(500, 66000);
        (remainingTime, goal, totalFunds) = fund.getCampaign(1);
        console2.log(remainingTime, goal, totalFunds);
        vm.stopPrank();

        vm.startPrank(user2);
        fund.createCampaign(2000, 66000);
        fund.contribute(1, 100);
        vm.stopPrank();

        vm.startPrank(user3);
        fund.createCampaign(3000, 36000);
        fund.contribute(1, 100);
        fund.contribute(2, 200);
        vm.stopPrank();     

        vm.prank(user4);
        fund.contribute(3, 3000);

        console2.log("getContribution[1][user2]:", fund.getContribution(1, user2));
        console2.log("getContribution[2][user3]:", fund.getContribution(2, user3));
        console2.log("getContribution[3][user3]:", fund.getContribution(3, user4));

        vm.prank(user4);
        vm.expectRevert();
        fund.withdrawFunds(3);

        vm.prank(user3);
        vm.expectRevert();
        fund.withdrawFunds(3);

        vm.warp(1641040000);      

        vm.prank(user3);
        fund.withdrawFunds(3);   

        vm.prank(user1);
        vm.expectRevert();
        fund.withdrawFunds(1);   

        (remainingTime, goal, totalFunds) = fund.getCampaign(3);
        console2.log(remainingTime, goal, totalFunds);

        console2.log("getContribution[1][user3]:", fund.getContribution(1, user3));
        console2.log("getContribution[2][user3]:", fund.getContribution(2, user3));
        console2.log("getContribution[3][user4]:", fund.getContribution(3, user4));     

        vm.prank(user4);
        vm.expectRevert();
        fund.refund(3);       

        (remainingTime, goal, totalFunds) = fund.getCampaign(2);
        console2.log(remainingTime, goal, totalFunds);    

        vm.prank(user1);
        vm.expectRevert();
        fund.cancelContribution(2);           

        vm.prank(user3);
        vm.expectRevert();
        fund.refund(2);       

        vm.warp(1641070000);      

        vm.prank(user3);
        vm.expectRevert();
        fund.cancelContribution(2);  

        vm.prank(user2);
        vm.expectRevert();
        fund.withdrawFunds(2);   

        vm.prank(user3);
        fund.refund(2);   

        (remainingTime, goal, totalFunds) = fund.getCampaign(2);
        console2.log(remainingTime, goal, totalFunds);  
    }

    function test_2() external {
        uint256 remainingTime;
        uint256 goal;
        uint256 totalFunds;

        vm.startPrank(user1);
        vm.expectRevert();
        fund.createCampaign(0, 10000);
        vm.expectRevert();
        fund.createCampaign(1000, 0); 
        fund.createCampaign(1000, 10000);   

        vm.expectRevert();
        fund.getCampaign(0);

        vm.expectRevert();
        fund.getCampaign(2);

        (remainingTime, goal, totalFunds) = fund.getCampaign(1);
        console2.log(remainingTime, goal, totalFunds);
        vm.stopPrank();

        fund.createCampaign(2, 2000);  
        vm.warp(1641001000);

        (remainingTime, goal, totalFunds) = fund.getCampaign(1);
        assertEq(remainingTime, 9000);
        (remainingTime, goal, totalFunds) = fund.getCampaign(2);
        assertEq(remainingTime, 1000);
    }

    function test_4() external {
        vm.startPrank(owner);
        token.mint(user1, 100000);
        token.mint(user2, 100000);
        vm.stopPrank();

        vm.prank(user1);
        token.approve(address(fund), 100000);

        vm.prank(user2);
        token.approve(address(fund), 100000);
        

        vm.prank(user1);
        fund.createCampaign(1000,10000);

        vm.prank(user2);
        fund.createCampaign(2000,15000);

        vm.prank(user1);
        fund.contribute(2, 100);

        vm.prank(user2);
        fund.contribute(1, 500);        

        vm.startPrank(user1);
        assertEq(fund.getContribution(1, user1), 0);
        assertEq(fund.getContribution(1, user2), 2500);
        assertEq(fund.getContribution(2, user1), 500);

        assertEq(token.balanceOf(user1), 99900);
        assertEq(token.balanceOf(user2), 99500);

        vm.expectRevert();
        fund.cancelContribution(0);
        vm.expectRevert();
        fund.cancelContribution(1);
        fund.cancelContribution(2);
        
        assertEq(fund.getContribution(2, user1), 0);
        assertEq(token.balanceOf(user1), 100000);
        vm.stopPrank();
    }  

    function test_5() external {
        uint256 remainingTime;
        uint256 goal;
        uint256 totalFunds;

        vm.startPrank(owner);
        token.mint(user1, 100000);
        token.mint(user2, 100000);
        vm.stopPrank();

        vm.prank(user1);
        token.approve(address(fund), 100000);

        vm.prank(user2);
        token.approve(address(fund), 100000);
        

        vm.prank(user1);
        fund.createCampaign(1000,10000);

        vm.prank(user1);
        fund.createCampaign(5000,70000);

        vm.prank(user2);
        fund.contribute(1, 100);

        vm.prank(user2);
        fund.contribute(1, 50);        

        vm.prank(user2);
        fund.contribute(2, 300);  

        vm.prank(user2);
        vm.expectRevert();
        fund.withdrawFunds(1);

        vm.prank(user1);
        vm.expectRevert();
        fund.withdrawFunds(1);

        (remainingTime, goal, totalFunds) = fund.getCampaign(1);
        assertEq(remainingTime, 10000);
        assertEq(goal, 1000);
        assertEq(totalFunds, 750);

        vm.warp(1641020000);

        (remainingTime, goal, totalFunds) = fund.getCampaign(2);
        assertEq(remainingTime, 50000);
        assertEq(goal, 5000);
        assertEq(totalFunds, 1500);    

        vm.prank(user1);
        vm.expectRevert();
        fund.withdrawFunds(2);

        vm.prank(user2);
        fund.contribute(2, 1000);

        (remainingTime, goal, totalFunds) = fund.getCampaign(2);
        assertEq(remainingTime, 50000);
        assertEq(goal, 5000);
        assertEq(totalFunds, 6500);  

        vm.prank(user1);
        vm.expectRevert();
        fund.withdrawFunds(2);      

        vm.warp(1641080000);

        vm.prank(user1);
        fund.withdrawFunds(2);   

        assertEq(token.balanceOf(user1), 101300);        
    }      

    function test_6() external {
        uint256 remainingTime;
        uint256 goal;
        uint256 totalFunds;

        vm.startPrank(owner);
        token.mint(user1, 100000);
        token.mint(user2, 100000);
        vm.stopPrank();

        vm.prank(user1);
        token.approve(address(fund), 100000);

        vm.prank(user2);
        token.approve(address(fund), 100000);
        

        vm.prank(user1);
        fund.createCampaign(1000,10000);

        vm.prank(user2);
        fund.contribute(1, 100);

        vm.prank(user2);
        fund.contribute(1, 400);        

        vm.warp(1641010000);

        vm.prank(user2);
        vm.expectRevert();
        fund.refund(1);  

        vm.prank(user1);
        fund.createCampaign(2500,10000);

        vm.prank(user2);
        fund.contribute(2, 100);

        vm.prank(user2);
        fund.contribute(2, 10);   

        vm.warp(1641030000);        

        vm.prank(user2);
        fund.refund(2);  

        assertEq(token.balanceOf(user2), 99500);        
    }         
}
