// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {StableX} from "../../src/StableX.sol";
import {DeployStableX} from "../../script/DeployStableX.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract StableXFuzz is Test {

    StableX public stableX;
    HelperConfig public helperConfig;

    address public OWNER;
    address public USER1 = makeAddr("user1");
    address public USER2 = makeAddr("user2");
    address public USER3 = makeAddr("user3");
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        DeployStableX deployer = new DeployStableX();
        (stableX, helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        OWNER = config.initialOwner;

        vm.deal(USER1, STARTING_BALANCE);
        vm.deal(USER2, STARTING_BALANCE);
        vm.deal(USER3, STARTING_BALANCE);
    }

    function testFuzz_TransferNeverExceedsBalance(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(to != OWNER);
        amount = bound(amount, 0, stableX.balanceOf(OWNER));

        vm.prank(OWNER);
        stableX.transfer(to, amount);

        assertEq(stableX.balanceOf(to), amount);
        assertEq(stableX.balanceOf(OWNER), stableX.totalSupply() - amount);
    }

    function testFuzz_MintNeverExceedsCap(uint256 mintAmount) public {
        uint256 cap = stableX.maxSupply();
        uint256 currentSupply = stableX.totalSupply();
        mintAmount = bound(mintAmount, 0, cap - currentSupply);

        vm.prank(OWNER);
        stableX.mint(USER1, mintAmount);

        assertEq(stableX.balanceOf(USER1), mintAmount);
        assertEq(stableX.totalSupply(), currentSupply + mintAmount);
        assertLe(stableX.totalSupply(), cap);
    }

    function testFuzz_BurnNeverExceedsTotalSupply(uint256 burnAmount) public {
        uint256 currentSupply = stableX.totalSupply();
        uint256 ownerBalance = stableX.balanceOf(OWNER);
        burnAmount = bound(burnAmount, 0, ownerBalance);

        vm.prank(OWNER);
        stableX.burn(burnAmount);

        assertEq(stableX.balanceOf(OWNER), ownerBalance - burnAmount);
        assertEq(stableX.totalSupply(), currentSupply - burnAmount);
    }

    function testFuzz_AllowanceDecreasesCorrectly(address spender, uint256 approved, uint256 spent) public {
        approved = bound(approved, 0, stableX.balanceOf(OWNER));
        spent = bound(spent, 0, approved);
        vm.assume(spender != address(0));
        vm.assume(spender != OWNER);

        vm.prank(OWNER);
        stableX.approve(spender, approved);

        vm.prank(spender);
        stableX.transferFrom(OWNER, USER3, spent);
        assertEq(stableX.allowance(OWNER, spender), approved - spent);
        assertEq(stableX.balanceOf(USER3), spent);
    }
}
