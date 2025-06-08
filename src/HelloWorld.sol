// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";

contract HelloWorld {
    constructor() {
        console.log("Hello World");
    }




    function sayHello() public pure returns (string memory) {
        return "Hello World";
    }
}