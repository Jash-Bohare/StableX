// test/invariant/Handler.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {StableX} from "../../src/StableX.sol";

contract Handler is Test {
    StableX public stableX;
    address public owner;

    // track all addresses that have received tokens
    // so invariant test can sum up all balances
    address[] public actors;
    mapping(address => bool) private _isActor;

    constructor(StableX _stableX, address _owner) {
        stableX = _stableX;
        owner = _owner;

        // owner is always an actor since they hold initial supply
        actors.push(owner);
        _isActor[owner] = true;
    }

    // helper to add new actors we discover
    function _addActor(address actor) internal {
        if (!_isActor[actor] && actor != address(0)) {
            actors.push(actor);
            _isActor[actor] = true;
        }
    }

    // Foundry will call these functions randomly
    function transfer(address to, uint256 amount) public {
        // guard against invalid inputs
        if (to == address(0)) return;
        if (stableX.isBlacklisted(msg.sender)) return;
        if (stableX.isBlacklisted(to)) return;

        uint256 senderBalance = stableX.balanceOf(owner);
        if (senderBalance == 0) return;

        amount = bound(amount, 1, senderBalance);

        vm.prank(owner);
        stableX.transfer(to, amount);

        _addActor(to);
    }

    function mint(uint256 amount) public {
        uint256 remaining = stableX.maxSupply() - stableX.totalSupply();
        if (remaining == 0) return;

        amount = bound(amount, 1, remaining);

        vm.prank(owner);
        stableX.mint(owner, amount);
    }

    function burn(uint256 amount) public {
        uint256 ownerBalance = stableX.balanceOf(owner);
        if (ownerBalance == 0) return;

        amount = bound(amount, 1, ownerBalance);

        vm.prank(owner);
        stableX.burn(amount);
    }

    // so invariant test can loop through all addresses
    function getActors() public view returns (address[] memory) {
        return actors;
    }
}
