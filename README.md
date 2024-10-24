# Fam Party Membership Authority Smart Contract

**A smart contract that serves as an Authority for managing party membership using Hypersub onchain subscriptions in conjunction with the Party Protocol. This contract allows adding and removing members from a party using party cards represented as tokens, leveraging Hypersub's subscription-based system and the Party Protocol's group coordination features.**

## JoinFamAuthority Contract

The JoinFamAuthority contract serves as an authority for managing party membership using Hypersub onchain subscriptions in conjunction with the Party Protocol. This contract allows adding and removing members from a party using party cards represented as tokens.

### Key Methods

1. `addPartyCards(address party, address[] calldata newPartyMembers, uint96[] calldata newPartyMemberVotingPowers, address[] calldata initialDelegates)`

   - Adds new party cards to the specified party.
   - Can add multiple members in a single transaction.
   - Updates the total voting power of the party.
   - Checks if each new member has an active Hypersub subscription.
   - Emits a `PartyCardAdded` event for each new member.

2. `setHypersub(address party, address hypersub)`
   - Sets the Hypersub address for a given party.
   - Can only be called by party hosts.
   - Emits a `HypersubSet` event.

### Key Features

- Prevents duplicate party card issuance to the same address.
- Ensures voting power is always positive for new party cards.
- Allows setting initial delegates for new party members.
- Integrates with the Party Protocol's governance system.
- Verifies active Hypersub subscriptions before minting party cards.

### Unit Tests

The contract includes comprehensive unit tests (in `JoinFamAuthority.t.sol`) to ensure its functionality:

1. `test_addPartyCards_single`: Tests adding a single party card.
2. `test_addPartyCards_multiple`: Verifies adding multiple party cards in one transaction.
3. `test_addPartyCards_multipleWithSameAddress`: Ensures that duplicate addresses are not allowed in a single transaction.
4. `test_addPartyCard_integration`: Tests the integration with the Party Protocol's proposal system.
5. `testSetHypersub`: Verifies the Hypersub setting functionality.
6. `testSetHypersubOnlyAuthorized`: Ensures only authorized users (hosts) can set the Hypersub address.
7. `test_addPartyCards_requiresActiveHypersubSubscription`: Verifies that only users with active Hypersub subscriptions can receive party cards.
8. `test_addPartyCards_requiresHypersubSet`: Ensures that a Hypersub address must be set for the party before adding party cards.

### Hypersub Integration

- The contract now checks the Hypersub subscription status of new members before minting party cards.
- It uses the `balanceOf` function of the Hypersub contract to verify active subscriptions.
- If a user doesn't have an active subscription, the `addPartyCards` function will revert with a `NoActiveSubscription` error.

### Error Handling

- `NoHypersubSet`: Thrown when trying to add party cards without setting a Hypersub address for the party.
- `NoActiveSubscription`: Thrown when trying to add a party card for a user without an active Hypersub subscription.
- `UserAlreadyHasPartyCard`: Thrown when trying to add a party card for a user who already has one.

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

- **Contract Address**: `0xa8b5d9765b03fA560725cd208396fF0104907e7F`
- **Transaction Hash**: `0xd6ce8aa6a024d79185c10a9389f6c3d8151ee50c67cbfc5cd701d315211c8f58`
- **Deployer Address**: `0x35CE1fb8CAa3758190ac65EDbcBC9647b8800e8f`

To deploy the contract yourself, use the following command:

```
forge script script/DeployJoinFamAuthority.s.sol:DeployJoinFamAuthority --rpc-url YOUR_RPC_URL --private-key YOUR_PRIVATE_KEY --broadcast --verify --etherscan-api-key BLOCK_SCANNER_API_KEY -vvvv
```

Make sure to replace `YOUR_RPC_URL`, `YOUR_PRIVATE_KEY`, and `BLOCK_SCANNER_API_KEY` with your actual values.
