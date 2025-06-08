// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title MyToken
 * @dev 实现ERC20标准的代币合约
 */
contract MyToken {
    // 代币名称
    string public name;
    // 代币符号
    string public symbol;
    // 代币小数位数
    uint8 public decimals;
    // 代币总供应量
    uint256 public totalSupply;
    
    // 账户余额映射
    mapping(address => uint256) public balanceOf;
    // 授权映射
    mapping(address => mapping(address => uint256)) public allowance;

    // 事件定义
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev 构造函数
     * @param _name 代币名称
     * @param _symbol 代币符号
     * @param _decimals 代币小数位数
     * @param _initialSupply 初始供应量
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        
        // 计算实际供应量（考虑小数位）
        uint256 supply = _initialSupply * 10**uint256(_decimals);
        
        // 分配初始供应量给合约创建者
        balanceOf[msg.sender] = supply;
        totalSupply = supply;
        
        emit Transfer(address(0), msg.sender, supply);
    }

    /**
     * @dev 转账函数
     * @param _to 接收者地址
     * @param _value 转账金额
     * @return 操作是否成功
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev 授权函数
     * @param _spender 被授权者地址
     * @param _value 授权金额
     * @return 操作是否成功
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "ERC20: approve to the zero address");
        
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev 授权转账函数
     * @param _from 发送者地址
     * @param _to 接收者地址
     * @param _value 转账金额
     * @return 操作是否成功
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(allowance[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev 增加授权金额
     * @param _spender 被授权者地址
     * @param _addedValue 增加的授权金额
     * @return 操作是否成功
     */
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        require(_spender != address(0), "ERC20: approve to the zero address");
        
        allowance[msg.sender][_spender] += _addedValue;
        
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev 减少授权金额
     * @param _spender 被授权者地址
     * @param _subtractedValue 减少的授权金额
     * @return 操作是否成功
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(_spender != address(0), "ERC20: approve to the zero address");
        require(allowance[msg.sender][_spender] >= _subtractedValue, "ERC20: decreased allowance below zero");
        
        allowance[msg.sender][_spender] -= _subtractedValue;
        
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev 销毁代币
     * @param _value 销毁金额
     * @return 操作是否成功
     */
    function burn(uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "ERC20: burn amount exceeds balance");
        
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
} 