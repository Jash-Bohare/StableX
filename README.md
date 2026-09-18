# StableX (STX)

A production-style ERC20 token built from scratch in Solidity — no OpenZeppelin imports in the core contract. StableX implements a hard-capped supply, two-role access control (MINTER and BLACKLISTER), and a USDC-style address blacklist. The goal of this project was to deeply understand ERC20 internals by building every piece manually, then testing it with unit tests, fuzz tests, and invariant tests using Foundry.

Deployed and verified on Sepolia: [`0xa63F71932EBa59b4E6a5E9BBA9c28a4B28dda813`](https://sepolia.etherscan.io/address/0xa63f71932eba59b4e6a5e9bba9c28a4b28dda813#code)

---

## Features

- **Hard supply cap** — `totalSupply` can never exceed `maxSupply`, enforced on every mint
- **Two-role access control** — separate MINTER and BLACKLISTER roles, both managed by a single owner
- **Blacklist mechanism** — blacklisted addresses cannot send, receive, or be minted to (same pattern used by USDC in production)
- **Deployer/owner separation** — the address paying gas to deploy can be different from the address that owns the contract
- **Infinite allowance support** — `type(uint256).max` allowance is never reduced, matching the ERC20 convention
- **Custom errors throughout** — no `require` strings anywhere, structured error data for all failure cases
- **Full test suite** — 25 unit tests, 4 fuzz tests (256 runs each), 2 invariant tests with a Handler

---

## Project Structure

```
StableX/
├── src/
│   └── StableX.sol                      # Core contract — no OZ imports
├── script/
│   ├── DeployStableX.s.sol              # Deployment script
│   ├── HelperConfig.s.sol               # Per-chain configuration
│   └── Interactions.s.sol               # Post-deploy role management
├── test/
│   ├── unit/
│   │   └── StableXTest.t.sol            # 25 unit tests
│   ├── fuzz/
│   │   └── StableXFuzz.t.sol            # 4 fuzz tests
│   └── invariant/
│       ├── Handler.t.sol                # Invariant handler
│       └── StableXInvariant.t.sol       # 2 invariant tests
├── .env.example
├── Makefile
└── foundry.toml
```

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- An Alchemy or Infura RPC URL for Sepolia (if deploying to testnet)

### Install

```bash
git clone https://github.com/Jash-Bohare/StableX
cd StableX
forge install
```

### Build

```bash
forge build
```

### Run Tests

```bash
# all tests
forge test -vv

# specific suite
forge test --match-path test/unit/StableXTest.t.sol -vv
forge test --match-path test/fuzz/StableXFuzz.t.sol -vv
forge test --match-path test/invariant/StableXInvariant.t.sol -vv

# gas report
forge test --gas-report

# coverage
forge coverage
```

---

## Deployment

### Environment setup

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

```
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-key
PRIVATE_KEY=0xyour-private-key
MY_WALLET_ADDRESS=0xyour-wallet-address
ETHERSCAN_API_KEY=your-etherscan-api-key
```

> Never commit `.env` to git. It is already in `.gitignore`.

### Deploy locally (Anvil)

```bash
# terminal 1
anvil

# terminal 2
make deploy-local
```

### Deploy to Sepolia

```bash
make deploy-test
```

This command deploys the contract and automatically verifies the source code on Etherscan in one step. You will see a verification URL in the output.

### Verify manually (if auto-verify fails)

```bash
forge verify-contract <CONTRACT_ADDRESS> src/StableX.sol:StableX \
  --chain sepolia \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(uint256,uint256,address)" \
    1000000000000000000000000 500000000000000000000000 <INITIAL_OWNER>)
```

---

## Gas Report

| Function            | Min   | Avg   | Median | Max   | # Calls |
|---------------------|-------|-------|--------|-------|---------|
| allowance           | 3179  | 3179  | 3179   | 3179  | 259     |
| approve             | 31104 | 50211 | 51280  | 51604 | 260     |
| balanceOf           | 2918  | 2918  | 2918   | 2918  | 4860    |
| blacklist           | 24462 | 44331 | 48305  | 48305 | 6       |
| burn                | 26800 | 36521 | 36662  | 36710 | 1584    |
| decimals            | 472   | 472   | 472    | 472   | 1       |
| grantMinter         | 24394 | 36194 | 36194  | 47994 | 4       |
| isBlacklisted       | 3002  | 3002  | 3002   | 3002  | 2764    |
| isBlacklister       | 2981  | 2981  | 2981   | 2981  | 1       |
| isMinter            | 2937  | 2937  | 2937   | 2937  | 4       |
| maxSupply           | 354   | 354   | 354    | 354   | 1628    |
| mint                | 24278 | 42854 | 39634  | 73846 | 1610    |
| name                | 66    | 661   | 661    | 661   | 1       |
| owner               | 2648  | 2648  | 2648   | 2648  | 3       |
| removeFromBlacklist | 26358 | 26358 | 26358  | 26358 | 1       |
| renounceOwnership   | 23443 | 23443 | 23443  | 23443 | 1       |
| revokeMinter        | 26114 | 26114 | 26114  | 26114 | 1       |
| symbol              | 660   | 660   | 660    | 660   | 1       |
| totalSupply         | 2499  | 2499  | 2499   | 2499  | 2914    |
| transfer            | 22135 | 56549 | 56864  | 56960 | 1583    |
| transferFrom        | 25412 | 64550 | 67418  | 67514 | 260     |
| transferOwnership   | 28930 | 28930 | 28930  | 28930 | 1       |

Deployment size: **11,853 bytes**

---

## Test Coverage

| File                        | % Lines        | % Statements   | % Branches    | % Funcs        |
|-----------------------------|----------------|----------------|---------------|----------------|
| script/DeployStableX.s.sol  | 100.00% (7/7)  | 100.00% (9/9)  | 100.00% (0/0) | 100.00% (1/1)  |
| script/HelperConfig.s.sol   | 31.25% (5/16)  | 40.00% (6/15)  | 16.67% (1/6)  | 20.00% (1/5)   |
| script/Interactions.s.sol   | 0.00% (0/12)   | 0.00% (0/10)   | 100.00% (0/0) | 0.00% (0/2)    |
| src/StableX.sol             | 78.06% (121/155)| 77.39% (89/115)| 39.39% (13/33)| 93.94% (31/33) |
| test/invariant/Handler.t.sol| 93.94% (31/33) | 97.50% (39/40) | 100.00% (7/7) | 83.33% (5/6)   |
| **Total**                   | **73.54%**     | **75.66%**     | **45.65%**    | **80.85%**     |

---

## Design Decisions

### 1. Deployer and owner are separate addresses

Most simple tokens set `_owner = msg.sender` in the constructor, which means whoever pays gas to deploy the contract automatically becomes the owner. This creates a coupling that causes problems in practice — teams often deploy from a hot wallet for convenience but want a multisig or a cold wallet to be the actual protocol owner.

StableX separates these concerns: the constructor takes an `initialOwner` parameter. The deployer pays gas, but ownership goes to whatever address is passed in. On testnet, both can be the same wallet. In production, the deployer would be a hot wallet and `initialOwner` would be a Gnosis Safe multisig.

### 2. Two separate role mappings instead of one generic system

The decision was to use explicit `_minters` and `_blacklisters` mappings rather than a single generic role system (like OpenZeppelin's `AccessControl` which uses `bytes32` role IDs). The explicit mapping approach is simpler to read and audit — anyone looking at the code immediately understands what roles exist and what they do, without needing to trace through a role registry.

The trade-off is extensibility: adding a new role means adding a new mapping and a new modifier. OpenZeppelin's approach makes adding roles trivial. For a token with exactly two roles that are unlikely to change, the simpler approach wins.

### 3. Blacklist checks on the operator in transferFrom

`transferFrom(from, to, amount)` involves three addresses: `from` (token owner), `to` (recipient), and `msg.sender` (the operator spending the allowance). This implementation checks all three for blacklist status, including `msg.sender`.

Most basic blacklist implementations only check `from` and `to`. But a blacklisted address should not be able to move anyone's tokens, even if they have an allowance. If the operator check is omitted, a blacklisted address could still drain allowances granted to it before it was blacklisted — which defeats the purpose of the blacklist entirely.

### 4. Infinite allowance is never reduced

When a spender has `type(uint256).max` allowance, `_spendAllowance` does not reduce it after each `transferFrom`. This matches the ERC20 convention adopted by WETH, most DEX routers, and OZ's own implementation.

The reason this convention exists: some protocols (like Uniswap's router) ask for max approval once so the user never has to approve again. If max allowance were reduced on every transfer, it would behave differently from what users and integrators expect, and would require re-approval after every interaction.

---

## What I Would Do Differently for Mainnet

**Timelock on sensitive role changes.** Right now the owner can grant or revoke the MINTER role instantly. On mainnet, this should go through a timelock contract (e.g. 48-hour delay) so the community can react if a malicious or compromised owner tries to mint unlimited tokens. Compound Governor's timelock is the standard pattern.

**Multisig as owner.** The `initialOwner` should be a Gnosis Safe with at least a 2-of-3 or 3-of-5 threshold. A single EOA as owner is a single point of failure — one compromised private key means the entire token is compromised.

**Blacklister role should probably not exist.** Or at minimum, it should be heavily restricted and timelocked. The ability to freeze arbitrary addresses is a significant centralisation risk. In a truly decentralised protocol, this role would either not exist or would require governance approval to use.

**Events for failed blacklist attempts.** Currently there are no events emitted when a blacklisted address tries to transact — only a revert. On-chain monitoring systems (Forta, custom bots) benefit from events for tracking attempted abuse.

---

## Comparison with OpenZeppelin's ERC20

After completing this implementation, the OZ source code was read line by line. Three key differences:

**1. OZ uses `unchecked` blocks in transfer math.**
In `_transfer`, OZ wraps the balance subtraction and addition in `unchecked { }`. Since Solidity 0.8+ reverts on overflow by default, OZ explicitly opts out of that check here because the balance check that precedes the arithmetic already guarantees no overflow or underflow is possible. The `unchecked` block saves roughly 200 gas per transfer. This implementation does not use `unchecked` — a deliberate choice to prioritise readability over gas for a learning project, but it would be the first gas optimisation applied on a production version.

**2. OZ's `_approve` does not check for zero address on the spender.**
The zero address check in `approve()` and `_approve()` is in OZ's public `approve()` function, not in the internal `_approve()`. This matters because `_approve()` is called internally from `transferFrom()` to reduce allowance — and in that path, both addresses are already validated. This implementation puts the zero address check inside the public function only, which matches OZ's actual intent even if the placement differs slightly.

**3. OZ uses a virtual/override inheritance pattern throughout.**
Every function in OZ's ERC20 is `virtual`, designed to be overridden by extensions like `ERC20Burnable`, `ERC20Pausable`, `ERC20Votes`. This implementation is a monolithic contract with no inheritance — all features are in one file. For a standalone token this is cleaner. For a library meant to be extended, OZ's approach is the right call.

---

## License

MIT
