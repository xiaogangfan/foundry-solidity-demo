# 众筹合约项目开发文档

本文档记录了使用Foundry框架开发、测试和部署众筹合约的完整流程，包含实际使用的命令和关键步骤。

## 1. 项目初始化

首先，我们使用Foundry的forge工具初始化项目：

```bash
# 创建项目目录
mkdir hello
cd hello

# 初始化Foundry项目
forge init
```

初始化后，Foundry会创建以下目录结构：

```
.
├── src/
│   └── Counter.sol         # 示例合约
├── test/
│   └── Counter.t.sol       # 示例测试
├── script/
│   └── Counter.s.sol       # 示例部署脚本
├── foundry.toml            # Foundry配置文件
└── .gitignore
```

## 2. 众筹合约开发

### 2.1 创建众筹合约

在`src`目录下创建`CrowdFunding.sol`文件：

```bash
touch src/CrowdFunding.sol
```

编写众筹合约代码：

```solidity
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
```

### 2.2 编译合约

使用forge build命令编译合约：

```bash
forge build
```

编译成功后，会在`out`目录下生成编译后的合约文件。

## 3. 合约测试

### 3.1 创建测试文件

在`test`目录下创建`CrowdFunding.t.sol`文件：

```bash
touch test/CrowdFunding.t.sol
```

编写测试代码：

```solidity
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
        assertTrue(claimed, unicode"提取后claimed状态应为true");
        
        // 不能重复提取
        vm.prank(creator);
        vm.expectRevert(unicode"资金已被提取");
        crowdfunding.finalize(campaignId);
    }

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
}
```

### 3.2 运行测试

使用forge test命令运行测试：

```bash
# 运行所有测试
forge test

# 运行测试并显示详细日志
forge test -vvv

# 运行特定测试
forge test --match-test testCreateCampaign -vvv
```

测试成功后，会显示测试通过的信息。

## 4. 部署脚本开发

### 4.1 创建部署脚本

在`script`目录下创建`CrowdFunding.s.sol`文件：

```bash
touch script/CrowdFunding.s.sol
```

编写部署脚本：

```solidity
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
```

## 5. 合约部署

### 5.1 启动本地开发节点

使用anvil启动本地开发节点：

```bash
anvil
```

这将启动一个本地以太坊节点，默认在http://127.0.0.1:8545上运行，并提供10个测试账户，每个账户有10000 ETH。

### 5.2 部署到本地节点

使用forge script命令部署合约到本地节点：

```bash
# 使用第一个测试账户的私钥部署
forge script script/CrowdFunding.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

部署成功后，会显示合约地址和交易哈希。

### 5.3 部署到测试网络

如果要部署到公共测试网络（如Sepolia），需要先获取测试网络的RPC URL和私钥，然后运行：

```bash
forge script script/CrowdFunding.s.sol --rpc-url <SEPOLIA_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast --verify
```

## 6. 与合约交互

### 6.1 使用Cast工具与合约交互

部署合约后，我们可以使用cast工具与合约交互：

```bash
# 创建众筹活动
cast send <CONTRACT_ADDRESS> "createCampaign(uint256,uint256,string,string)" 1000000000000000000 604800 "测试众筹项目" "这是一个用于测试的众筹项目" --private-key <PRIVATE_KEY> --rpc-url http://localhost:8545

# 向众筹活动捐款
cast send <CONTRACT_ADDRESS> "pledge(uint256)" 0 --value 0.5ether --private-key <PRIVATE_KEY> --rpc-url http://localhost:8545

# 查询众筹活动信息
cast call <CONTRACT_ADDRESS> "getCampaign(uint256)" 0 --rpc-url http://localhost:8545

# 检查活动是否成功
cast call <CONTRACT_ADDRESS> "isCampaignSuccessful(uint256)" 0 --rpc-url http://localhost:8545

# 提取资金（活动成功后）
cast send <CONTRACT_ADDRESS> "finalize(uint256)" 0 --private-key <PRIVATE_KEY> --rpc-url http://localhost:8545
```

### 6.2 使用Etherscan验证合约

如果部署到公共测试网络，可以使用以下命令验证合约：

```bash
forge verify-contract <DEPLOYED_CONTRACT_ADDRESS> src/CrowdFunding.sol:Crowdfunding --chain sepolia --etherscan-api-key <YOUR_ETHERSCAN_API_KEY>
```

## 7. 实际开发过程中的命令记录

以下是开发过程中实际使用的命令记录：

```bash
# 初始化项目
forge init hello
cd hello

# 编写合约
vim src/CrowdFunding.sol

# 编译合约
forge build

# 编写测试
vim test/CrowdFunding.t.sol

# 运行测试
forge test
forge test -vvv

# 编写部署脚本
vim script/CrowdFunding.s.sol

# 启动本地节点
anvil

# 部署到本地节点
forge script script/CrowdFunding.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

# 与合约交互
# 假设合约地址为0x5FbDB2315678afecb367f032d93F642f64180aa3
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getDebugCampaignCount()" --rpc-url http://localhost:8545

# 创建众筹活动
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "createCampaign(uint256,uint256,string,string)" 1000000000000000000 604800 "测试众筹项目" "这是一个用于测试的众筹项目" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://localhost:8545

# 向众筹活动捐款
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "pledge(uint256)" 0 --value 500000000000000000 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d --rpc-url http://localhost:8545

# 查询众筹活动信息
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getCampaign(uint256)" 0 --rpc-url http://localhost:8545
```

## 8. 总结

通过本文档，我们完整记录了使用Foundry框架开发众筹合约的全过程，包括：

1. 项目初始化
2. 合约开发
3. 合约测试
4. 部署脚本开发
5. 合约部署
6. 与合约交互

这些步骤和命令可以作为后续开发的参考，帮助快速回顾和复现开发流程。 