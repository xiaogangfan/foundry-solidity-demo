// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenScript is Script {
    function setUp() public {}

    function run() public {
        // 获取私钥，如果没有设置则使用默认私钥
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 部署代币合约
        // 参数：名称、符号、小数位数、初始供应量
        MyToken token = new MyToken("My Token", "MTK", 18, 1000000);
        console.log("MyToken deployed to:", address(token));
        
        // 获取代币信息
        string memory tokenName = token.name();
        string memory tokenSymbol = token.symbol();
        uint8 tokenDecimals = token.decimals();
        uint256 tokenSupply = token.totalSupply();
        
        console.log("Token Name:", tokenName);
        console.log("Token Symbol:", tokenSymbol);
        console.log("Token Decimals:", tokenDecimals);
        console.log("Total Supply (with decimals):", tokenSupply);
        console.log("Total Supply (human readable):", tokenSupply / 10**tokenDecimals);
        
        // 获取部署者余额
        address deployer = vm.addr(deployerPrivateKey);
        uint256 deployerBalance = token.balanceOf(deployer);
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployerBalance / 10**tokenDecimals);

        // 结束广播交易
        vm.stopBroadcast();
    }
} 