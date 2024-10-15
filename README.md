# Fam Party Membership Authority Smart Contract

**A smart contract that serves as an Authority for managing party membership using Hypersub onchain subscriptions in conjunction with the Party Protocol. This contract allows adding and removing members from a party using party cards represented as tokens, leveraging Hypersub's subscription-based system and the Party Protocol's group coordination features.**

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

## Deploy - JoinFamAuthority

The JoinFamAuthority contract has been deployed to Base Sepolia testnet. Here are the latest deployment details:

- **Contract Address**: `0xAA0C69957a3F056a52fa9408146AC02608Bb5068`
- **Transaction Hash**: `0x8466eb8fb26be478780dd20ed035f4c6d98a8add2cdb5a8e8b28aa95de316d11`
- **Deployer Address**: `0x35CE1fb8CAa3758190ac65EDbcBC9647b8800e8f`

```
forge script script/DeployJoinFamAuthority.s.sol:DeployJoinFamAuthority --rpc-url YOUR_RPC_URL --private-key YOUR_PRIVATE_KEY --broadcast --verify --etherscan-api-key BLOCK_SCANNER_API_KEY -vvvv
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
