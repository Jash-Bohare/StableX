build:
	forge build

test:
	forge test -vv

clean:
	forge clean

coverage:
	forge coverage

snapshot:
	forge snapshot

gas:
	forge test --gas-report

deploy-local:
	forge script script/DeployStableX.s.sol --rpc-url $(ANVIL_RPC_URL) --private-key $(ANVIL_PRIVATE_KEY) --broadcast -vvvv

deploy-test:
	forge script script/DeployStableX.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
