// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { CrowdFundHard } from "../src/CrowdFundHard.sol";
import { MyToken } from "../src/MyToken.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


contract CrowdFundHardTest is PRBTest, StdCheats {
    CrowdFundHard internal fund;
    MyToken internal token1;
    MyToken internal token2;
    MyToken internal token3;

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
        token1 = new MyToken("Token1", "TKN1", 1);
        token2 = new MyToken("Token2", "TKN2", 4);
        token3 = new MyToken("Token3", "TKN3", 5);
        address[] memory tokens = new address[](3);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        tokens[2] = address(token3);
        fund = new CrowdFundHard(tokens);

        vm.warp(1641000000);     
         
    }

    function test_3() external {
        vm.startPrank(owner);
        token1.mint(user1, 100000);
        token2.mint(user1, 100000);
        token1.mint(user2, 100000);       
        vm.stopPrank(); 

        vm.startPrank(user1);
        token1.approve(address(fund), 100000);    
        token2.approve(address(fund), 100000);          
        vm.stopPrank();   

        vm.warp(1641000010); 
        vm.prank(user1);
        fund.createCampaign(1000, 10000);
        
        vm.warp(1641000110); 
        vm.prank(user2);
        fund.createCampaign(100, 20000);
        vm.warp(1641000220);


        vm.startPrank(user1);
        vm.expectRevert();
        fund.contribute(1, address(token1), 100);

        vm.expectRevert();
        fund.contribute(0, address(token1), 100);        

        vm.expectRevert();
        fund.contribute(2, address(token1), 0);     

        vm.expectRevert();
        fund.contribute(2, address(token3), 100);     

        vm.warp(1641015220);

        fund.contribute(2, address(token1), 100);  

        vm.expectRevert();
        fund.getContribution(0, user1); 

        assertEq(fund.getContribution(1, user1), 0); 

        assertEq(fund.getContribution(1, user2), 0); 

        assertEq(fund.getContribution(2, user1), 100); 
        vm.stopPrank();
    }


    function test_7() external {
        uint256 remainingTime;
        uint256 goal;
        uint256 totalFunds;
        vm.startPrank(owner);
        token1.mint(user2, 100000);
        token2.mint(user2, 100000);
        token3.mint(user2, 100000);
        token1.mint(user1, 100000);
        token2.mint(user1, 100000);
        token3.mint(user3, 100000);        
        vm.stopPrank(); 

        vm.startPrank(user1);
        token1.approve(address(fund), 100000);    
        token2.approve(address(fund), 100000);          
        vm.stopPrank();
        vm.startPrank(user2);
        token1.approve(address(fund), 100000);    
        token2.approve(address(fund), 100000);    
        token3.approve(address(fund), 100000);        
        vm.stopPrank();
        vm.startPrank(user3);   
        token3.approve(address(fund), 100000);        
        vm.stopPrank();      

        vm.prank(user1);
        fund.createCampaign(1000, 10000);
        
        vm.prank(user1);
        fund.createCampaign(5000, 40000);

        vm.prank(user2);
        fund.createCampaign(400, 15000);

        vm.startPrank(user2);
        fund.contribute(1, address(token2), 30);
        fund.contribute(1, address(token3), 10);        
        fund.contribute(2, address(token2), 100);     
        vm.stopPrank();

        vm.startPrank(user1);
        fund.contribute(3, address(token1), 100);
        fund.contribute(3, address(token2), 100);     
        vm.stopPrank();

        vm.startPrank(user3);
        fund.contribute(1, address(token3), 50);   
        vm.stopPrank();

        vm.startPrank(user1);
        assertEq(token2.balanceOf(user2), 99870); 

        (remainingTime, goal, totalFunds) = fund.getCampaign(1);
        assertEq(remainingTime, 10000); 
        assertEq(goal, 1000); 
        assertEq(totalFunds, 420); 

        (remainingTime, goal, totalFunds) = fund.getCampaign(2);
        assertEq(remainingTime, 40000); 
        assertEq(goal, 5000); 
        assertEq(totalFunds, 400); 

        vm.warp(1641001300);

        vm.expectRevert();
        fund.withdrawFunds(1);
        vm.stopPrank();

        vm.prank(user2);
        fund.contribute(1, address(token3), 200);     

        vm.startPrank(user1);
        vm.warp(1641011300);
        fund.withdrawFunds(1);

        vm.expectRevert();
        fund.getCampaign(1);

        assertEq(token3.balanceOf(user1), 260); 
        vm.stopPrank();

        vm.prank(user2);
        fund.cancelContribution(2);
        
        (remainingTime, goal, totalFunds) = fund.getCampaign(2);
        assertEq(remainingTime, 28700); 
        assertEq(goal, 5000); 
        assertEq(totalFunds, 0); 
        
        vm.prank(user1);
        fund.cancelContribution(3);
        
        (remainingTime, goal, totalFunds) = fund.getCampaign(3);
        assertEq(remainingTime, 3700); 
        assertEq(goal, 400); 
        assertEq(totalFunds, 0); 

    }       
}
