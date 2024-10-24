// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/Script.sol";
import {ManageFamAuthority} from "../src/ManageFamAuthority.sol";

contract DeployManageFamAuthority is Script {
    function run() public {
        vm.startBroadcast();

        ManageFamAuthority authority = new ManageFamAuthority();

        console.log("ManageFamAuthority deployed at:", address(authority));

        vm.stopBroadcast();
    }
}
