// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";

contract CrowdfundingTest is Test {
    Crowdfunding public crowdfunding;
    address public creator = address(1);
    address public contributor1 = address(2);
    address public contributor2 = address(3);

    // 测试参数
    uint256 public goal = 10 ether;
    uint256 public duration = 7 days;
    string public title = unicode"测试众筹项目";
    string public description = unicode"这是一个用于测试的众筹项目";

    function setUp() public {
        crowdfunding = new Crowdfunding();
        vm.deal(contributor1, 5 ether);
        vm.deal(contributor2, 10 ether);
    }

    function testCreateCampaign() public {
        vm.prank(creator);
        uint256 campaignId = crowdfunding.createCampaign(goal, duration, title, description);
        
        assertEq(campaignId, 0, unicode"第一个活动ID应为0");
        
        (
            address _creator,
            uint256 _goal,
            uint256 _pledged,
            uint256 _startTime,
            uint256 _endTime,
            bool _claimed,
            string memory _title,
            string memory _description
        ) = crowdfunding.getCampaign(campaignId);
        
        assertEq(_creator, creator, unicode"创建者地址不匹配");
        assertEq(_goal, goal, unicode"目标金额不匹配");
        assertEq(_pledged, 0, unicode"初始筹集金额应为0");
        assertEq(_endTime - _startTime, duration, unicode"持续时间不匹配");
        assertEq(_claimed, false, unicode"初始claimed状态应为false");
        assertEq(_title, title, unicode"标题不匹配");
        assertEq(_description, description, unicode"描述不匹配");
    }

    function testPledge() public {
        // 创建活动
        vm.prank(creator);
        uint256 campaignId = crowdfunding.createCampaign(goal, duration, title, description);
        
        // 捐款
        vm.prank(contributor1);
        crowdfunding.pledge{value: 2 ether}(campaignId);
        
        (,, uint256 pledged,,,,, ) = crowdfunding.getCampaign(campaignId);
        assertEq(pledged, 2 ether, unicode"筹集金额不匹配");
        assertEq(crowdfunding.getPledgedAmount(campaignId, contributor1), 2 ether, unicode"捐款人捐款记录不匹配");
        
        // 第二次捐款
        vm.prank(contributor1);
        crowdfunding.pledge{value: 1 ether}(campaignId);
        
        (,, pledged,,,,, ) = crowdfunding.getCampaign(campaignId);
        assertEq(pledged, 3 ether, unicode"多次捐款后总金额不匹配");
        assertEq(crowdfunding.getPledgedAmount(campaignId, contributor1), 3 ether, unicode"多次捐款后记录不匹配");
    }

    function testWithdrawPledge() public {
        // 创建活动
        vm.prank(creator);
        uint256 campaignId = crowdfunding.createCampaign(goal, duration, title, description);
        
        // 捐款
        vm.prank(contributor1);
        crowdfunding.pledge{value: 3 ether}(campaignId);
        
        // 活动结束前不能取回
        vm.prank(contributor1);
        vm.expectRevert(unicode"众筹活动尚未结束");
        crowdfunding.withdrawPledge(campaignId);
        
        // 时间快进到活动结束
        vm.warp(block.timestamp + duration + 1);
        
        // 取回捐款
        uint256 balanceBefore = contributor1.balance;
        vm.prank(contributor1);
        crowdfunding.withdrawPledge(campaignId);
        uint256 balanceAfter = contributor1.balance;
        
        assertEq(balanceAfter - balanceBefore, 3 ether, unicode"取回金额不正确");
        assertEq(crowdfunding.getPledgedAmount(campaignId, contributor1), 0, unicode"取回后捐款记录应为0");
    }

    function testFinalize() public {
        // 创建活动
        vm.prank(creator);
        uint256 campaignId = crowdfunding.createCampaign(goal, duration, title, description);
        
        // 捐款达到目标
        vm.prank(contributor1);
        crowdfunding.pledge{value: 5 ether}(campaignId);
        
        vm.prank(contributor2);
        crowdfunding.pledge{value: 6 ether}(campaignId);
        
        // 活动结束前不能提取
        vm.prank(creator);
        vm.expectRevert(unicode"众筹活动尚未结束");
        crowdfunding.finalize(campaignId);
        
        // 时间快进到活动结束
        vm.warp(block.timestamp + duration + 1);
        
        // 提取资金
        uint256 balanceBefore = creator.balance;
        vm.prank(creator);
        crowdfunding.finalize(campaignId);
        uint256 balanceAfter = creator.balance;
        
        assertEq(balanceAfter - balanceBefore, 11 ether, unicode"提取金额不正确");
        
        // 检查活动状态
        (,,,,,bool claimed,,) = crowdfunding.getCampaign(campaignId);
        assertTrue(claimed,     unicode"提取后claimed状态应为true");
        
        // 不能重复提取
        vm.prank(creator);
        vm.expectRevert(unicode"资金已被提取");
        crowdfunding.finalize(campaignId);
    }

    // function testFailedCampaign() public {
    //     // 创建活动
    //     vm.prank(creator);
    //     uint256 campaignId = crowdfunding.createCampaign(goal, duration, title, description);
        
    //     // 捐款未达到目标
    //     vm.prank(contributor1);
    //     crowdfunding.pledge{value: 3 ether}(campaignId);
        
    //     // 时间快进到活动结束
    //     vm.warp(block.timestamp + duration + 1);
        
    //     // 创建者不能提取资金
    //     vm.prank(creator);
    //     vm.expectRevert(unicode"众筹目标未达成");
    //     crowdfunding.finalize(campaignId);
        
    //     // 捐款人可以取回资金
    //     uint256 balanceBefore = contributor1.balance;
    //     vm.prank(contributor1);
    //     crowdfunding.withdrawPledge(campaignId);
    //     uint256 balanceAfter = contributor1.balance;
        
    //     assertEq(balanceAfter - balanceBefore, 3 ether, unicode"取回金额不正确");
    // }

    function testSuccessfulCampaignCheck() public {
        // 创建活动
        vm.prank(creator);
        uint256 campaignId = crowdfunding.createCampaign(goal, duration, title, description);
        
        // 捐款达到目标
        vm.prank(contributor2);
        crowdfunding.pledge{value: 10 ether}(campaignId);
        
        // 时间快进到活动结束
        vm.warp(block.timestamp + duration + 1);
        
        // 检查活动是否成功
        bool isSuccessful = crowdfunding.isCampaignSuccessful(campaignId);
        assertTrue(isSuccessful, unicode"活动应该成功");
    }

    // function testFailedCampaignCheck() public {
    //     // 创建活动
    //     vm.prank(creator);
    //     uint256 campaignId = crowdfunding.createCampaign(goal, duration, title, description);
        
    //     // 捐款未达到目标
    //     vm.prank(contributor1);
    //     crowdfunding.pledge{value: 3 ether}(campaignId);
        
    //     // 时间快进到活动结束
    //     vm.warp(block.timestamp + duration + 1);
        
    //     // 检查活动是否成功
    //     bool isSuccessful = crowdfunding.isCampaignSuccessful(campaignId);
    //     console.log("isSuccessful", isSuccessful);
    //     assertFalse(isSuccessful, unicode"活动应该失败");
    // }
} 