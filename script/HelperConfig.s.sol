// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;

    address constant ANVIL_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    error HelperConfig__InvalidChainId(uint256 chainId);

    struct NetworkConfig {
        uint256 maxSupply;
        uint256 initialMint;
        address initialOwner;
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getLocalConfig();
        } else if (chainId == ETH_SEPOLIA_CHAIN_ID) {
            return getSepoliaConfig();
        } else if (chainId == ETH_MAINNET_CHAIN_ID) {
            return getMainnetConfig();
        } else {
            revert HelperConfig__InvalidChainId(chainId);
        }
    }

    function getLocalConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({maxSupply: 1_000_000e18, initialMint: 500_000e18, initialOwner: ANVIL_ADDRESS});
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            maxSupply: 1_000_000e18, initialMint: 500_000e18, initialOwner: vm.envAddress("MY_WALLET_ADDRESS")
        });
    }

    function getMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            maxSupply: 1_000_000e18, initialMint: 500_000e18, initialOwner: vm.envAddress("MY_WALLET_ADDRESS")
        });
    }
}

