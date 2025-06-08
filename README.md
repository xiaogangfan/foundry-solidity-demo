# 众筹合约项目文档

本项目是一个基于Solidity的众筹系统，使用Foundry框架进行开发、测试和部署。

## 项目结构

```
.
├── src/
│   └── CrowdFunding.sol    # 众筹合约源代码
├── test/
│   └── CrowdFunding.t.sol  # 众筹合约测试代码
├── script/
│   └── CrowdFunding.s.sol  # 众筹合约部署脚本
└── foundry.toml            # Foundry配置文件
```

## 合约功能

众筹合约(`CrowdFunding.sol`)实现了以下功能：

1. **创建众筹活动**：用户可以创建新的众筹活动，设置目标金额、持续时间、标题和描述。
2. **捐款**：用户可以向指定的众筹活动捐款。
3. **取回捐款**：如果众筹活动失败（未达到目标金额），捐款人可以取回资金。
4. **提取资金**：如果众筹活动成功（达到目标金额），创建者可以提取所有资金。
5. **查询功能**：查询众筹活动信息、捐款金额、活动是否成功等。

## 开发流程

### 1. 合约开发

众筹合约(`CrowdFunding.sol`)包含以下主要组件：

- **数据结构**：使用`Campaign`结构体存储众筹活动信息。
- **状态变量**：使用映射存储众筹活动和捐款信息。
- **事件**：定义事件用于记录重要操作。
- **函数**：实现创建活动、捐款、取回资金、提取资金等功能。

### 2. 合约测试

测试文件(`CrowdFunding.t.sol`)使用Foundry的测试框架，测试了合约的各项功能：

- **测试创建活动**：验证活动创建后的各项参数是否正确。
- **测试捐款**：验证捐款功能和金额记录是否正确。
- **测试取回捐款**：验证在活动失败时捐款人能否正确取回资金。
- **测试提取资金**：验证在活动成功时创建者能否正确提取资金。
- **测试活动状态检查**：验证活动成功/失败状态的判断是否正确。

运行测试：
```bash
forge test
```

### 3. 合约部署

部署脚本(`CrowdFunding.s.sol`)使用Foundry的脚本功能：

- 部署众筹合约
- 创建一个测试众筹活动
- 打印活动信息

部署到测试网络：
```bash
forge script script/CrowdFunding.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## 合约调用示例

### 创建众筹活动

```solidity
// 目标金额：1 ETH
// 持续时间：7天
// 标题：测试众筹项目
// 描述：这是一个用于测试的众筹项目
uint256 campaignId = crowdfunding.createCampaign(
    1 ether,
    7 days,
    "测试众筹项目",
    "这是一个用于测试的众筹项目"
);
```

### 向众筹活动捐款

```solidity
// 向ID为0的活动捐款0.5 ETH
crowdfunding.pledge{value: 0.5 ether}(0);
```

### 取回捐款（活动失败时）

```solidity
// 从ID为0的活动取回捐款
crowdfunding.withdrawPledge(0);
```

### 提取资金（活动成功时）

```solidity
// 从ID为0的活动提取资金
crowdfunding.finalize(0);
```

### 查询活动信息

```solidity
// 获取ID为0的活动信息
(
    address creator,
    uint256 goal,
    uint256 pledged,
    uint256 startTime,
    uint256 endTime,
    bool claimed,
    string memory title,
    string memory description
) = crowdfunding.getCampaign(0);
```

## Foundry 工具使用指南

Foundry 是一个用 Rust 编写的高效以太坊开发工具包，包含三个主要工具：Forge、Anvil 和 Cast。

### Forge - 合约开发与测试工具

Forge 是 Foundry 的核心工具，用于编译、测试和部署 Solidity 智能合约。

#### 常用命令

1. **初始化项目**
```bash
forge init my_project
```
创建一个新的 Foundry 项目，包含基本的目录结构和示例文件。

2. **编译合约**
```bash
forge build
```
编译 `src/` 目录下的所有 Solidity 合约。

3. **运行测试**
```bash
# 运行所有测试
forge test

# 运行指定测试
forge test --match-test testCreateCampaign

# 运行测试并显示详细日志
forge test -vvv
```

4. **部署合约**
```bash
# 使用脚本部署
forge script script/CrowdFunding.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast

# 直接部署合约
forge create src/CrowdFunding.sol:Crowdfunding --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>
```

5. **生成气体报告**
```bash
forge snapshot
```
生成测试的气体消耗报告。

6. **格式化代码**
```bash
forge fmt
```
格式化 Solidity 代码。

### Anvil - 本地开发节点

Anvil 是一个本地以太坊节点，类似于 Ganache，用于本地开发和测试。

#### 常用命令

1. **启动本地节点**
```bash
anvil
```
启动一个本地以太坊节点，默认在 http://127.0.0.1:8545 上运行。

2. **指定账户数量**
```bash
anvil --accounts 20
```
启动节点并创建 20 个测试账户。

3. **指定区块时间**
```bash
anvil --block-time 5
```
设置每 5 秒自动生成一个新区块。

4. **指定分叉网络**
```bash
anvil --fork-url <RPC_URL>
```
从指定的网络（如主网或测试网）分叉状态。

### Cast - 区块链交互工具

Cast 是一个用于与以太坊区块链和智能合约交互的命令行工具。

#### 常用命令

1. **查询账户余额**
```bash
cast balance <ADDRESS> --rpc-url <RPC_URL>
```
查询指定地址的 ETH 余额。

2. **发送交易**
```bash
cast send <CONTRACT_ADDRESS> "pledge(uint256)" 0 --value 0.5ether --private-key <PRIVATE_KEY> --rpc-url <RPC_URL>
```
向众筹合约发送 0.5 ETH 的捐款。

3. **调用合约函数**
```bash
cast call <CONTRACT_ADDRESS> "getCampaign(uint256)" 0 --rpc-url <RPC_URL>
```
调用合约的 `getCampaign` 函数查询 ID 为 0 的活动信息。

4. **转换数据格式**
```bash
# 将 ETH 转换为 Wei
cast --to-wei 1.5

# 将 Wei 转换为 ETH
cast --from-wei 1500000000000000000

# 将文本转换为十六进制
cast --format-bytes32 "Hello"
```

5. **获取区块信息**
```bash
# 获取最新区块号
cast block-number --rpc-url <RPC_URL>

# 获取区块信息
cast block latest --rpc-url <RPC_URL>
```

6. **获取交易信息**
```bash
cast tx <TX_HASH> --rpc-url <RPC_URL>
```
获取指定交易的详细信息。

## 众筹合约开发实战示例

### 1. 使用 Forge 编译合约
```bash
forge build
```

### 2. 使用 Forge 运行测试
```bash
forge test -vvv
```

### 3. 启动 Anvil 本地节点
```bash
anvil
```

### 4. 使用 Forge 部署合约到本地节点
```bash
forge script script/CrowdFunding.s.sol --rpc-url http://localhost:8545 --private-key <PRIVATE_KEY> --broadcast
```

### 5. 使用 Cast 与合约交互
```bash
# 创建众筹活动
cast send <CONTRACT_ADDRESS> "createCampaign(uint256,uint256,string,string)" 1000000000000000000 604800 "测试众筹项目" "这是一个用于测试的众筹项目" --private-key <PRIVATE_KEY> --rpc-url http://localhost:8545

# 向众筹活动捐款
cast send <CONTRACT_ADDRESS> "pledge(uint256)" 0 --value 0.5ether --private-key <PRIVATE_KEY> --rpc-url http://localhost:8545

# 查询众筹活动信息
cast call <CONTRACT_ADDRESS> "getCampaign(uint256)" 0 --rpc-url http://localhost:8545
```

## 注意事项

1. 所有金额单位均为wei，在前端交互时需要进行单位转换。
2. 众筹活动一旦创建，目标金额和持续时间不可更改。
3. 众筹活动结束前，捐款人不能取回捐款。
4. 众筹活动成功后，捐款人不能取回捐款。
5. 众筹活动失败后，创建者不能提取资金。

## 安全考虑

1. 合约使用了`call`方法发送ETH，避免了重入攻击的风险。
2. 所有关键操作都有适当的权限检查和状态验证。
3. 合约包含详细的事件记录，便于追踪操作历史。
