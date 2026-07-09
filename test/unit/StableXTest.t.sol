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
    uint256 public constant STARTING_BALANCE = 100 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        DeployStableX deployer = new DeployStableX();
        (stableX, helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        OWNER = config.initialOwner;

        vm.deal(USER1, STARTING_BALANCE);
        vm.deal(USER2, STARTING_BALANCE);
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

}
