// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";

contract CrowdfundingScript is Script {
    Crowdfunding public crowdfunding;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // 部署众筹合约
        crowdfunding = new Crowdfunding();
        console.log(unicode"众筹合约已部署到地址:", address(crowdfunding));

        // 创建一个测试众筹活动
        uint256 goal = 1 ether;
        uint256 duration = 7 days;
        string memory title = unicode"测试众筹项目";
        string memory description = unicode"这是一个用于测试的众筹项目";
        
        uint256 campaignId = crowdfunding.createCampaign(goal, duration, title, description);
        console.log(unicode"已创建测试众筹活动，ID:", campaignId);
        
        // 获取活动信息并打印
        (
            address creator,
            uint256 _goal,
            uint256 pledged,
            uint256 startTime,
            uint256 endTime,
            bool claimed,
            string memory _title,
            string memory _description
        ) = crowdfunding.getCampaign(campaignId);
        
        console.log(unicode"活动创建者:", creator);
        console.log(unicode"目标金额:", _goal);
        console.log(unicode"开始时间:", startTime);
        console.log(unicode"结束时间:", endTime);
        console.log(unicode"活动标题:", _title);

        vm.stopBroadcast();
    }
} 