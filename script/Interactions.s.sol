// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {StableX} from "../src/StableX.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract GrantMinter is Script {
    function run(address newMinter) external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("StableX", block.chainid);

        vm.startBroadcast();

        StableX(mostRecentDeployment).grantMinter(newMinter);

        vm.stopBroadcast();
    }
}

contract GrantBlacklister is Script {
    function run(address newBlacklister) external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("StableX", block.chainid);

        vm.startBroadcast();

        StableX(mostRecentDeployment).grantBlacklister(newBlacklister);

        vm.stopBroadcast();
    }
}
