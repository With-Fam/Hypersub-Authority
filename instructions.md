# Product Requirements Document: Hypersub Party Membership Authority Smart Contract

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

### 3.1 Mint New Party Cards

The smart contract shall:

- Allow the minting of a new Party Card (NFT) to a user, subject to specific conditions.
- Before minting, verify that:
  1. The user has an active Hypersub subscription.
  2. The user's current balance of Party NFTs for this specific party is zero (partyNft.balanceOf(user) === 0).
- If both conditions are met, mint a new Party Card to the user.
- Assign appropriate voting power to the newly minted Party Card.
- Implement the functionality as demonstrated in the `./src/AddPartyCardsAuthority.sol` example file, adapted for the verification and minting process.
- Use the `balanceOf` method in the hypersub subscription contract as demonstrated in `./src/TODO_HYPERSUB_CONTRACT.sol`. If the value is greater than zero, the user has an active hypersub membership and the minting process should succeed as long as they do not already have a Party Card for the party.

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
