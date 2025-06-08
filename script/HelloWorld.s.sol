// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {HelloWorld} from "../src/HelloWorld.sol";

contract HelloWorldScript is Script {
    function setUp() public {}

    function run() public {
        // 获取私钥，如果没有设置则使用默认私钥
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 部署HelloWorld合约
        HelloWorld helloWorld = new HelloWorld();
        console.log("HelloWorld contract deployed to:", address(helloWorld));
        
        // 调用sayHello函数并打印结果
        string memory greeting = helloWorld.sayHello();
        console.log("Greeting from contract:", greeting);

        // 结束广播交易
        vm.stopBroadcast();
    }
} 