// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title 众筹合约
 * @dev 允许创建众筹活动、捐款和提取资金
 */
contract Crowdfunding {
    // 众筹活动结构
    struct Campaign {
        address creator;         // 活动创建者
        uint256 goal;            // 目标金额(wei)
        uint256 pledged;         // 已筹集金额(wei)
        uint256 startTime;       // 开始时间
        uint256 endTime;         // 结束时间
        bool claimed;            // 是否已提取资金
        string title;            // 活动标题
        string description;      // 活动描述
    }

    // 活动ID到活动数据的映射
    mapping(uint256 => Campaign) public campaigns;
    // 活动ID到捐款人地址到捐款金额的映射
    mapping(uint256 => mapping(address => uint256)) public pledgedAmount;
    // 活动总数
    uint256 public campaignCount;

    // 事件定义
    event CampaignCreated(uint256 indexed id, address indexed creator, uint256 goal, uint256 startTime, uint256 endTime, string title);
    event PledgeAdded(uint256 indexed id, address indexed contributor, uint256 amount);
    event PledgeWithdrawn(uint256 indexed id, address indexed contributor, uint256 amount);
    event CampaignFinalized(uint256 indexed id, bool successful, uint256 amountPaid);
    // 调试事件
    event DebugLog(string message);
    event DebugLogUint(string message, uint256 value);
    event DebugLogAddress(string message, address value);
    event DebugLogString(string message, string value);

    /**
     * @dev 创建新的众筹活动
     * @param _goal 目标金额(wei)
     * @param _duration 活动持续时间(秒)
     * @param _title 活动标题
     * @param _description 活动描述
     */
    function createCampaign(
        uint256 _goal,
        uint256 _duration,
        string memory _title,
        string memory _description
    ) external returns (uint256) {
        emit DebugLog(unicode"开始创建众筹活动");
        emit DebugLogUint(unicode"目标金额", _goal);
        emit DebugLogUint(unicode"持续时间", _duration);
        emit DebugLogString(unicode"标题", _title);
        
        require(_goal > 0, unicode"目标金额必须大于0");
        require(_duration > 0, unicode"持续时间必须大于0");
        require(bytes(_title).length > 0, unicode"标题不能为空");

        uint256 campaignId = campaignCount++;
        emit DebugLogUint(unicode"分配的活动ID", campaignId);
        
        Campaign storage campaign = campaigns[campaignId];
        campaign.creator = msg.sender;
        campaign.goal = _goal;
        campaign.startTime = block.timestamp;
        campaign.endTime = block.timestamp + _duration;
        campaign.title = _title;
        campaign.description = _description;
        
        emit DebugLogAddress(unicode"创建者地址", msg.sender);
        emit DebugLogUint(unicode"开始时间", campaign.startTime);
        emit DebugLogUint(unicode"结束时间", campaign.endTime);
        
        emit CampaignCreated(campaignId, msg.sender, _goal, campaign.startTime, campaign.endTime, _title);
        emit DebugLog(unicode"众筹活动创建完成");
        
        return campaignId;
    }

    /**
     * @dev 向众筹活动捐款
     * @param _id 活动ID
     */
    function pledge(uint256 _id) external payable {
        emit DebugLogUint(unicode"尝试向活动ID捐款", _id);
        emit DebugLogUint(unicode"捐款金额", msg.value);
        
        Campaign storage campaign = campaigns[_id];
        emit DebugLogAddress(unicode"活动创建者", campaign.creator);
        emit DebugLogUint(unicode"活动目标金额", campaign.goal);
        
        require(block.timestamp >= campaign.startTime, unicode"众筹活动尚未开始");
        require(block.timestamp <= campaign.endTime, unicode"众筹活动已结束");
        require(msg.value > 0, unicode"捐款金额必须大于0");
        
        campaign.pledged += msg.value;
        pledgedAmount[_id][msg.sender] += msg.value;
        
        emit DebugLogUint(unicode"活动当前筹集金额", campaign.pledged);
        emit DebugLogUint(unicode"捐款人总捐款金额", pledgedAmount[_id][msg.sender]);
        
        emit PledgeAdded(_id, msg.sender, msg.value);
        emit DebugLog(unicode"捐款成功");
    }

    /**
     * @dev 如果众筹失败，捐款人可以取回资金
     * @param _id 活动ID
     */
    function withdrawPledge(uint256 _id) external {
        emit DebugLogUint(unicode"尝试从活动ID取回捐款", _id);
        
        Campaign storage campaign = campaigns[_id];
        emit DebugLogUint(unicode"活动目标金额", campaign.goal);
        emit DebugLogUint(unicode"活动当前筹集金额", campaign.pledged);
        emit DebugLogUint(unicode"活动结束时间", campaign.endTime);
        emit DebugLogUint(unicode"当前时间", block.timestamp);
        
        require(block.timestamp > campaign.endTime, unicode"众筹活动尚未结束");
        require(campaign.pledged < campaign.goal, unicode"众筹活动已成功，无法取回捐款");
        
        uint256 amount = pledgedAmount[_id][msg.sender];
        emit DebugLogUint(unicode"可取回金额", amount);
        
        require(amount > 0, unicode"没有可取回的捐款");
        
        pledgedAmount[_id][msg.sender] = 0;
        campaign.pledged -= amount;
        
        emit DebugLogUint(unicode"取回后活动筹集金额", campaign.pledged);
        emit PledgeWithdrawn(_id, msg.sender, amount);
        
        emit DebugLog(unicode"开始转账");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, unicode"转账失败");
        emit DebugLog(unicode"取回捐款成功");
    }

    /**
     * @dev 众筹成功后，创建者可以提取资金
     * @param _id 活动ID
     */
    function finalize(uint256 _id) external {
        emit DebugLogUint(unicode"尝试完成活动ID", _id);
        
        Campaign storage campaign = campaigns[_id];
        emit DebugLogAddress(unicode"活动创建者", campaign.creator);
        emit DebugLogAddress(unicode"调用者", msg.sender);
        emit DebugLogUint(unicode"活动目标金额", campaign.goal);
        emit DebugLogUint(unicode"活动当前筹集金额", campaign.pledged);
        emit DebugLogUint(unicode"活动结束时间", campaign.endTime);
        emit DebugLogUint(unicode"当前时间", block.timestamp);
        emit DebugLogUint(unicode"是否已提取", campaign.claimed ? 1 : 0);
        
        require(msg.sender == campaign.creator, unicode"只有创建者可以提取资金");
        require(block.timestamp > campaign.endTime, unicode"众筹活动尚未结束");
        require(campaign.pledged >= campaign.goal, unicode"众筹目标未达成");
        require(!campaign.claimed, unicode"资金已被提取");
        
        campaign.claimed = true;
        
        emit CampaignFinalized(_id, true, campaign.pledged);
        
        emit DebugLog(unicode"开始转账");
        (bool success, ) = payable(campaign.creator).call{value: campaign.pledged}("");
        require(success, unicode"转账失败");
        emit DebugLog(unicode"提取资金成功");
    }

    /**
     * @dev 获取众筹活动信息
     * @param _id 活动ID
     */
    function getCampaign(uint256 _id) external view returns (
        address creator,
        uint256 goal,
        uint256 pledged,
        uint256 startTime,
        uint256 endTime,
        bool claimed,
        string memory title,
        string memory description
    ) {
        Campaign storage campaign = campaigns[_id];
        return (
            campaign.creator,
            campaign.goal,
            campaign.pledged,
            campaign.startTime,
            campaign.endTime,
            campaign.claimed,
            campaign.title,
            campaign.description
        );
    }

    /**
     * @dev 检查众筹活动是否成功
     * @param _id 活动ID
     */
    function isCampaignSuccessful(uint256 _id) external view returns (bool) {
        Campaign storage campaign = campaigns[_id];
        return (block.timestamp > campaign.endTime && campaign.pledged >= campaign.goal);
    }

    /**
     * @dev 获取用户对某活动的捐款金额
     * @param _id 活动ID
     * @param _contributor 捐款人地址
     */
    function getPledgedAmount(uint256 _id, address _contributor) external view returns (uint256) {
        return pledgedAmount[_id][_contributor];
    }
    
    /**
     * @dev 调试函数：获取当前活动数量
     */
    function getDebugCampaignCount() external view returns (uint256) {
        return campaignCount;
    }
    
    /**
     * @dev 调试函数：检查活动是否存在
     */
    function campaignExists(uint256 _id) external view returns (bool) {
        Campaign storage campaign = campaigns[_id];
        // 检查创建者地址是否为非零地址，作为活动存在的简单检查
        return campaign.creator != address(0);
    }
} 