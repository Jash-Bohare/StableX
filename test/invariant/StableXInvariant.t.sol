// test/invariant/StableXInvariant.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {StableX} from "../../src/StableX.sol";
import {DeployStableX} from "../../script/DeployStableX.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Handler} from "./Handler.t.sol";

contract StableXInvariant is Test {
    StableX public stableX;
    Handler public handler;
    address public OWNER;

    function setUp() public {
        DeployStableX deployer = new DeployStableX();
        HelperConfig helperConfig;
        (stableX, helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        OWNER = config.initialOwner;

        // deploy handler and tell Foundry to only call the handler
        handler = new Handler(stableX, OWNER);
        targetContract(address(handler));
    }

    // Foundry runs this after every random sequence of handler calls
    // if this ever returns false, the invariant is broken

    function invariant_totalSupplyEqualsBalanceSum() public view {
        // sum up every actor's balance
        address[] memory actors = handler.getActors();
        uint256 totalBalances = 0;

        for (uint256 i = 0; i < actors.length; i++) {
            totalBalances += stableX.balanceOf(actors[i]);
        }

        assertEq(totalBalances, stableX.totalSupply());
    }

    function invariant_totalSupplyNeverExceedsCap() public view {
        assertLe(stableX.totalSupply(), stableX.maxSupply());
    }
}
