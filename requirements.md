# Product Requirements Document: Fam Party Membership Authority Smart Contract

## 1. Introduction

### 1.1 Purpose

This document outlines the requirements for a smart contract that serves as an Authority for managing party membership using Hypersub onchain subscriptions in conjunction with the Party Protocol. The contract will allow adding and removing members from a party using party cards represented as tokens, leveraging Hypersub's subscription-based system and the Party Protocol's group coordination features.

### 1.2 Scope

The scope of this project includes the development of a Solidity smart contract, testing using Foundry, and deployment scripts for the Hypersub Party Membership Authority. This contract will integrate with Hypersub's onchain subscription functionality and the Party Protocol.

### 1.3 Definitions

- Hypersub: A blockchain-based subscription management system.
- Onchain Subscription: A subscription service managed entirely on the blockchain through smart contracts.
- Party Protocol: An open protocol for group coordination on Ethereum, providing onchain functionality for group formation, coordination, and distribution.
- Party: A group formed and managed through the Party Protocol, which members can subscribe to using Hypersub.
- Party Cards: NFTs (ERC721) representing membership in a specific Party. Each Party Card has its own amount of voting power.
- TokenId: A unique identifier for each party subscription token.

## 2. Product Overview

### 2.1 Product Description

The Hypersub Party Membership Authority Smart Contract is a decentralized application (DApp) that manages the membership of parties on the blockchain using Hypersub's onchain subscription system in conjunction with the Party Protocol. It allows for the addition and removal of party cards, which represent voting membership in a party, enhancing the Party Protocol's group coordination capabilities with subscription-based features.

### 2.2 Technical Stack

- Smart Contract Language: Solidity
- Testing Framework: Foundry
- Deployment Tools: Foundry
- Integrations:
  - Hypersub onchain subscription system
  - Party Protocol

## 3. Functional Requirements

### 3.1 Join Fam Authority

The smart contract shall:

- Implement a `setHypersub` function with the following signature:
  ```solidity
  function setHypersub(address party, address hypersubAddress) external
  ```
- Maintain a mapping of party addresses to their associated Hypersub subscription addresses:
  ```solidity
  mapping(address => address) public partyToHypersub;
  ```
- Implement access control to ensure only authorized entities (e.g., party owner or admin) can set the Hypersub address for a party.
- Emit a `HypersubSet` event when a Hypersub address is set for a party:
  ```solidity
  event HypersubSet(address indexed party, address indexed hypersubAddress);
  ```
- Implement an `addPartyCards` function with the following signature:
  ```solidity
  function addPartyCards(
      address party,
      address[] calldata newPartyMembers,
      uint96[] calldata newPartyMemberVotingPowers,
      address[] calldata initialDelegates
  ) external
  ```
- Allow the minting of new Party Cards (NFTs) to users for a specific party, subject to specific conditions.
- Before minting, verify that:
  1. The user has an active Hypersub subscription by checking `hypersub.balanceOf(user) > 0`, where `hypersub` is the address stored in `partyToHypersub[party]`.
  2. The user's current balance of Party NFTs for the specified party is zero (partyNft.balanceOf(user) === 0).
  - If partyNft.balanceOf(user) > 0, throw an error with the message: "UserAlreadyHasPartyCard".
- If both conditions are met, mint a new Party Card to the user for the specified party.
- Assign appropriate voting power to the newly minted Party Card based on the `newPartyMemberVotingPowers` parameter.
- Set the initial delegate for each new party member using the `initialDelegates` parameter.
- Implement the functionality as demonstrated in the `./src/AddPartyCardsAuthority.sol` example file, adapted for the verification and minting process.
- Ensure that the lengths of `newPartyMembers`, `newPartyMemberVotingPowers`, and `initialDelegates` arrays match.
- Implement proper error handling for cases such as:
  - Invalid party address
  - No party members provided
  - Mismatched array lengths
  - Invalid party member address (e.g., zero address)
  - Invalid voting power (e.g., zero voting power)
  - Hypersub address not set for the party
- Emit a `PartyCardAdded` event for each successfully minted Party Card, including the party address.

### 3.2 Remove Party Cards

The smart contract shall:

- Implement the reference functionality as demonstrated in the `./src/AddPartyCardsAuthority.sol` example file, adapted for Party Card removal.
- Call the `burn` function of the `./src/PartyGovernanceNFT.sol` contract to remove Party Cards.
- Before burning, verify that:
  1. The user does not have an active Hypersub subscription.
  2. The user's current balance of Party NFTs for this specific party is greater than zero (partyNft.balanceOf(user) > 0).
- Allow the burning of Party Cards from a member who's hypersub subscription has expired, effectively ending the user's membership in the party.
- Remove membership based on the provided tokenId.

### 3.3 Subscription and Membership Management

The smart contract shall:

- Interface with Hypersub's onchain subscription system to verify active subscriptions.
- Provide functions to check subscription status and Party Card ownership.
- Handle cases where a user's Hypersub subscription expires, burning the Party Card.
- Implement functions to update voting power of Party Cards if necessary.

## 4. Non-Functional Requirements

### 4.1 Security

- Implement access control to ensure only authorized entities can add or remove party cards.
- Use best practices for smart contract security, including protection against common vulnerabilities.

### 4.2 Performance

- Optimize gas usage for all contract functions.
- Ensure efficient scaling for parties with high membership activation / churn.

### 4.3 Compatibility

- Ensure compatibility with the latest stable version of Solidity and Foundry.
- Design the contract to be compatible with standard ERC token interfaces, if applicable.
- Compatible with Party Protocol.
- Compatible with Hypersub onchain subscription system.

## 5. Testing Requirements

### 5.1 Unit Testing

- Develop comprehensive unit tests using Foundry for all contract functions.
- Achieve at least 95% code coverage through unit tests.
- Implement GitHub Actions to automatically run unit tests on every push and pull request.

### 5.2 Integration Testing

- Perform integration tests to ensure proper interaction between contract functions.
- Test edge cases and potential failure scenarios.

## 6. Continuous Integration

### 6.1 GitHub Actions

- Set up a GitHub Actions workflow to automate the testing process.
- The workflow should:
  - Trigger on every push to the main branch and on all pull requests.
  - Install dependencies and set up the Foundry environment.
  - Run all unit tests using Foundry.
  - Report test results and code coverage.
  - Fail the workflow if any tests fail or if code coverage is below the 95% threshold.

### 6.2 Reporting

- Generate and store test reports as artifacts in GitHub Actions.
- Implement a badge in the repository README to display the current status of tests.

## 7. Future Considerations

### 7.1 Upgradability

- Consider implementing an upgradable contract pattern for future improvements.

### 7.2 Governance

- Explore the possibility of implementing onchain governance for party management decisions.

## 8. Version Control and Collaboration

### 8.1 GitHub Repository

- Host the project in a GitHub repository.
- Utilize GitHub features such as issues, pull requests, and project boards for project management.

### 8.2 Branching Strategy

- Implement a branching strategy for organized development.
- Require pull requests and code reviews before merging into the main branch.

### 8.3 Documentation

- Maintain up-to-date documentation in the repository, including:
  - README with project overview and setup instructions
  - Contributing guidelines
  - Code of conduct
- NATSPEC documentation comments are added to all smart contracts and functions.

## 9. Acceptance Criteria

The project will be considered complete when:

1. All functional and non-functional requirements are implemented and tested.
2. The smart contract passes all unit and integration tests with the required code coverage.
3. Deployment scripts are created and successfully tested on a test network.
4. Documentation for NATSPEC, usage, testing, and deployment is complete and accurate.
5. Minimal code is used to achieve the functionality.
6. Clean code by Uncle Bob Martin's standards are folled throughout the codebase.
7. GitHub Actions are set up and successfully running automated tests on every push and pull request.

## 10. Deployment

### 10.1 Prerequisites

- Obtain an RPC URL from chainlist (https://chainlist.org/?search=base&testnets=true) for the Base Sepolia testnet.
- Create a new private key specifically for deployment. This key may be visible to others, so do not use it for any other purpose.
- Add some ETH to the newly created address on the Base Sepolia testnet.
- Obtain a BlockScanner API key from BaseScan (https://basescan.org/myapikey).

### 10.2 Deployment Script

- Create a deployment script named `DeployJoinFamAuthority.s.sol` in the `script/` directory.
- The script should handle the deployment of the JoinFamAuthority contract.

### 10.3 Deployment Command

Use the following command to deploy the JoinFamAuthority contract:

```
forge script script/DeployJoinFamAuthority.s.sol:DeployJoinFamAuthority --rpc-url YOUR_RPC_URL --private-key YOUR_PRIVATE_KEY --broadcast --verify --etherscan-api-key BLOCK_SCANNER_API_KEY -vvvv
```

Replace the following placeholders:

- `YOUR_RPC_URL`: The RPC URL obtained from chainlist for Base Sepolia.
- `YOUR_PRIVATE_KEY`: The private key created for deployment.
- `BLOCK_SCANNER_API_KEY`: The API key obtained from BaseScan.

### 10.4 Verification

- Ensure the deployment script includes steps to verify the contract on BaseScan.
- After successful deployment, confirm that the contract is verified and accessible on BaseScan.

### 10.5 Documentation

- Update the README with the deployed contract address and any specific instructions for interacting with the deployed contract.
- Document any environment-specific configurations or parameters used during deployment.

### 10.6 Testing on Testnet

- After deployment, perform a series of tests on the Base Sepolia testnet to ensure all functionalities work as expected in a live environment.
- Document any issues encountered during testnet deployment and testing, and update the contract or deployment process if necessary.
