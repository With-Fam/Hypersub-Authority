// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/Script.sol";
import {JoinFamAuthority} from "../src/JoinFamAuthority.sol";

contract DeployJoinFamAuthority is Script {
    function run() public {
        vm.startBroadcast();

        JoinFamAuthority authority = new JoinFamAuthority();

        console.log("JoinFamAuthority deployed at:", address(authority));

        vm.stopBroadcast();
    }
}
