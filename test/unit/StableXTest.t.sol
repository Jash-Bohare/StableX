// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {StableX} from "../../src/StableX.sol";
import {DeployStableX} from "../../script/DeployStableX.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract StableXTest is Test{

    StableX public stableX;
    HelperConfig public helperConfig;

    address public OWNER;
    address public USER1 = makeAddr("user1");
    address public USER2 = makeAddr("user2");
    address public USER3 = makeAddr("user3");
    uint256 public constant STARTING_BALANCE = 100 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        DeployStableX deployer = new DeployStableX();
        (stableX, helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        OWNER = config.initialOwner;

        vm.deal(USER1, STARTING_BALANCE);
        vm.deal(USER2, STARTING_BALANCE);
        vm.deal(USER3, STARTING_BALANCE);
    }

    function testInitialSupplyMintedToOwner() public {
        uint256 ownerBalance = stableX.balanceOf(OWNER);
        uint256 totalSupply = stableX.totalSupply();
        assertEq(ownerBalance, totalSupply);
    }

    function testNameSymbolDecimalsCorrect() public {
        assertEq(stableX.name(), "StableX");
        assertEq(stableX.symbol(), "STX");
        assertEq(stableX.decimals(), 18);
    }

    function testMaxSupplySetCorrectly() public {
        uint256 maxSupply = stableX.maxSupply();
        uint256 providedMaxSupply = helperConfig.getConfig().maxSupply;
        assertEq(maxSupply, providedMaxSupply);
    }

    function testDeployerHasAllRoles() public {
        assertEq(stableX.owner(), OWNER);
        assertTrue(stableX.isMinter(OWNER));
        assertTrue(stableX.isBlacklister(OWNER));
    }

    function testTransfer() public {
        uint256 transferAmount = 100e18;
        vm.startPrank(OWNER);
        vm.expectEmit(true, true, false, true, address(stableX));
        emit Transfer(OWNER, USER1, transferAmount);
        stableX.transfer(USER1, transferAmount);
        vm.stopPrank();

        assertEq(stableX.balanceOf(USER1), transferAmount);
        assertEq(stableX.balanceOf(OWNER), stableX.totalSupply() - transferAmount);
    }

    function testTransferRevertsIfZeroAddress() public {
        uint256 transferAmount = 100e18;
        vm.startPrank(OWNER);
        vm.expectRevert(StableX.StableX__ZeroAddress.selector);
        stableX.transfer(address(0), transferAmount);
        vm.stopPrank();
    }

    function testTransferRevertsIfInsufficientBalance() public {
        uint256 transferAmount = 100e18;
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(StableX.StableX__InsufficientBalance.selector, USER1, 0, transferAmount));
        stableX.transfer(USER2, transferAmount);
        vm.stopPrank();
    }

    function testApproveAndTransferFrom() public {
        vm.startPrank(OWNER);
        stableX.transfer(USER1, 150);
        vm.stopPrank();

        vm.startPrank(USER1);
        stableX.approve(USER2, 100);
        vm.stopPrank();

        vm.startPrank(USER2);
        stableX.transferFrom(USER1, USER3, 10);
        vm.stopPrank();

        assertEq(stableX.allowance(USER1, USER2), 90);
    }

    function testInfiniteAllowanceNotReduced() public {
        uint256 maxAllowance = type(uint256).max;
        vm.startPrank(OWNER);
        stableX.transfer(USER1, 150);
        vm.stopPrank();

        vm.startPrank(USER1);
        stableX.approve(USER2, maxAllowance);
        vm.stopPrank();

        vm.startPrank(USER2);
        stableX.transferFrom(USER1, USER3, 10);
        vm.stopPrank();

        assertEq(stableX.allowance(USER1, USER2), maxAllowance);
    }

    function testTransferFromRevertsIfBelowAllowance() public {
        vm.startPrank(OWNER);
        stableX.transfer(USER1, 150);
        vm.stopPrank();

        vm.startPrank(USER1);
        stableX.approve(USER2, 100);
        vm.stopPrank();

        vm.startPrank(USER2);
        vm.expectRevert(abi.encodeWithSelector(StableX.StableX__InsufficientAllowance.selector, USER1, USER2, stableX.allowance(USER1, USER2), 150));
        stableX.transferFrom(USER1, USER3, 150);
        vm.stopPrank();
    }

    function testMintIncreasesSupply() public {
        uint256 mintAmount = 500;
        uint256 beforeMint = stableX.totalSupply();
        vm.startPrank(OWNER);
        stableX.mint(USER1, mintAmount);
        uint256 afterMint = stableX.totalSupply();
        vm.stopPrank();
        assertEq(afterMint, beforeMint + mintAmount);
    }

    function testMintRevertsIfExceedsCap() public {
        uint256 mintAmount = 600_000e18;
        uint256 cap = stableX.maxSupply();
        uint256 totalSupply = stableX.totalSupply();

        vm.startPrank(OWNER);
        vm.expectRevert(abi.encodeWithSelector(StableX.StableX__CapExceeded.selector, totalSupply, mintAmount, cap));
        stableX.mint(USER1, mintAmount);
        vm.stopPrank();
    }

    function testMintRevertsIfCallerNotMinter() public {
        uint256 mintAmount = 500;

        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(StableX.StableX__Unauthorized.selector, USER1));
        stableX.mint(USER2, mintAmount);
        vm.stopPrank();
    }

    function testBurnReducesSupply() public {
        uint256 burnAmount = 500;
        uint256 beforeBurn = stableX.totalSupply();
        vm.startPrank(OWNER);
        stableX.burn(burnAmount);
        uint256 afterBurn = stableX.totalSupply();
        vm.stopPrank();
        assertEq(afterBurn, beforeBurn - burnAmount);
    }

    function testBurnRevertsIfInsufficientBalance() public {
        uint256 burnAmount = 600_000e18;
        uint256 balance = stableX.balanceOf(OWNER);

        vm.startPrank(OWNER);
        vm.expectRevert(abi.encodeWithSelector(StableX.StableX__InsufficientBalance.selector, OWNER, balance, burnAmount));
        stableX.burn(burnAmount);
        vm.stopPrank();
    }

    function testBlacklistedSenderCannotTransfer() public {
        uint256 amount = 100;
        vm.startPrank(OWNER);
        stableX.transfer(USER1, 200);
        stableX.blacklist(USER1);
        vm.stopPrank();

        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(StableX.StableX__Blacklisted.selector, USER1));
        stableX.transfer(USER2, amount);
        vm.stopPrank();
    }

    function testBlacklistedRecipientCannotReceive() public {
        uint256 amount = 100;
        vm.startPrank(OWNER);
        stableX.transfer(USER1, 200);
        stableX.blacklist(USER2);
        vm.stopPrank();

        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(StableX.StableX__Blacklisted.selector, USER2));
        stableX.transfer(USER2, amount);
        vm.stopPrank();
    }

    function testBlacklistedAddressCannotMintReceive() public {
        uint256 mintAmount = 500;

        vm.startPrank(OWNER);
        stableX.blacklist(USER1);
        vm.expectRevert(abi.encodeWithSelector(StableX.StableX__Blacklisted.selector, USER1));
        stableX.mint(USER1, mintAmount);
        vm.stopPrank();
    }

    function testRemoveFromBlacklistRestoresTransfer() public {
        uint256 amount = 100;
        uint256 initialBalance = stableX.balanceOf(USER2);

        vm.startPrank(OWNER);
        stableX.transfer(USER1, 200);
        stableX.blacklist(USER1);
        stableX.removeFromBlacklist(USER1);
        vm.stopPrank();

        vm.startPrank(USER1);
        stableX.transfer(USER2, amount);
        uint256 finalBalance = stableX.balanceOf(USER2);
        vm.stopPrank();

        assertEq(finalBalance, initialBalance + amount);
    }

    function testBlacklistRevertsIfCallerNotBlacklister() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(StableX.StableX__Unauthorized.selector, USER1));
        stableX.blacklist(USER2);
        vm.stopPrank();
    }

    function testTransferOwnership() public {
        vm.prank(OWNER);
        stableX.transferOwnership(USER1);
        assertEq(stableX.owner(), USER1);
    }

    function testRenounceOwnershipLocksAdmin() public {
        vm.prank(OWNER);
        stableX.renounceOwnership();
        assertEq(stableX.owner(), address(0));
    }

    function testGrantAndRevokeRole() public {
        vm.startPrank(OWNER);
        stableX.grantMinter(USER1);
        assertTrue(stableX.isMinter(USER1));
        stableX.revokeMinter(USER1);
        assertFalse(stableX.isMinter(USER1));
        vm.stopPrank();
    }
}
