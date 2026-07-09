// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {StableX} from "../src/StableX.sol";

contract DeployStableX is Script {

    function run() external returns(StableX, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

        vm.startBroadcast();
        StableX stableX = new StableX(
            networkConfig.maxSupply,
            networkConfig.initialMint,
            networkConfig.initialOwner
        );
        vm.stopBroadcast();

        return (stableX, helperConfig);
    }
}
