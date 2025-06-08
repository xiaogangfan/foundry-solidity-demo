// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken public token;
    address public deployer = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    
    // 测试参数
    string public name = "My Token";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public initialSupply = 1000000;
    
    function setUp() public {
        vm.prank(deployer);
        token = new MyToken(name, symbol, decimals, initialSupply);
    }
    
    function testInitialState() public view {
        assertEq(token.name(), name, "Name should match");
        assertEq(token.symbol(), symbol, "Symbol should match");
        assertEq(token.decimals(), decimals, "Decimals should match");
        assertEq(token.totalSupply(), initialSupply * 10**decimals, "Total supply should match");
        assertEq(token.balanceOf(deployer), initialSupply * 10**decimals, "Deployer balance should match total supply");
    }
    
    function testTransfer() public {
        uint256 amount = 1000 * 10**decimals;
        
        vm.prank(deployer);
        bool success = token.transfer(user1, amount);
        
        assertTrue(success, "Transfer should succeed");
        assertEq(token.balanceOf(user1), amount, "Recipient balance should increase");
        assertEq(token.balanceOf(deployer), (initialSupply * 10**decimals) - amount, "Sender balance should decrease");
    }
    
    // function testFailTransferInsufficientBalance() public {
    //     uint256 amount = (initialSupply + 1) * 10**decimals;
        
    //     vm.prank(deployer);
    //     token.transfer(user1, amount);
    // }
    
    function testApproveAndTransferFrom() public {
        uint256 amount = 1000 * 10**decimals;
        
        // 授权
        vm.prank(deployer);
        bool approveSuccess = token.approve(user1, amount);
        assertTrue(approveSuccess, "Approve should succeed");
        assertEq(token.allowance(deployer, user1), amount, "Allowance should be set");
        
        // 授权转账
        vm.prank(user1);
        bool transferSuccess = token.transferFrom(deployer, user2, amount);
        
        assertTrue(transferSuccess, "TransferFrom should succeed");
        assertEq(token.balanceOf(user2), amount, "Recipient balance should increase");
        assertEq(token.balanceOf(deployer), (initialSupply * 10**decimals) - amount, "Owner balance should decrease");
        assertEq(token.allowance(deployer, user1), 0, "Allowance should be spent");
    }
    
    // function testFailTransferFromInsufficientAllowance() public {
    //     uint256 approveAmount = 500 * 10**decimals;
    //     uint256 transferAmount = 1000 * 10**decimals;
        
    //     // 授权金额小于转账金额
    //     vm.prank(deployer);
    //     token.approve(user1, approveAmount);
        
    //     vm.prank(user1);
    //     token.transferFrom(deployer, user2, transferAmount);
    // }
    
    function testIncreaseAllowance() public {
        uint256 initialAmount = 1000 * 10**decimals;
        uint256 increaseAmount = 500 * 10**decimals;
        
        vm.startPrank(deployer);
        token.approve(user1, initialAmount);
        token.increaseAllowance(user1, increaseAmount);
        vm.stopPrank();
        
        assertEq(token.allowance(deployer, user1), initialAmount + increaseAmount, "Allowance should increase");
    }
    
    function testDecreaseAllowance() public {
        uint256 initialAmount = 1000 * 10**decimals;
        uint256 decreaseAmount = 400 * 10**decimals;
        
        vm.startPrank(deployer);
        token.approve(user1, initialAmount);
        token.decreaseAllowance(user1, decreaseAmount);
        vm.stopPrank();
        
        assertEq(token.allowance(deployer, user1), initialAmount - decreaseAmount, "Allowance should decrease");
    }
    
    // function testFailDecreaseAllowanceBelowZero() public {
    //     uint256 initialAmount = 500 * 10**decimals;
    //     uint256 decreaseAmount = 1000 * 10**decimals;
        
    //     vm.startPrank(deployer);
    //     token.approve(user1, initialAmount);
    //     token.decreaseAllowance(user1, decreaseAmount);
    //     vm.stopPrank();
    // }
    
    function testBurn() public {
        uint256 burnAmount = 1000 * 10**decimals;
        uint256 initialTotalSupply = token.totalSupply();
        
        vm.prank(deployer);
        bool success = token.burn(burnAmount);
        
        assertTrue(success, "Burn should succeed");
        assertEq(token.totalSupply(), initialTotalSupply - burnAmount, "Total supply should decrease");
        assertEq(token.balanceOf(deployer), initialTotalSupply - burnAmount, "Burner balance should decrease");
    }
    
    // function testFailBurnInsufficientBalance() public {
    //     uint256 burnAmount = (initialSupply + 1) * 10**decimals;
        
    //     vm.prank(deployer);
    //     token.burn(burnAmount);
    // }
} 