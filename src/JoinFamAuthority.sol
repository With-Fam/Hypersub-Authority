// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import {Party} from "@party/contracts/party/Party.sol";
import {PartyGovernanceNFT} from "@party/contracts/party/PartyGovernanceNFT.sol";
import {SubscriptionTokenV1} from "./hypersub/SubscriptionTokenV1.sol";

contract JoinFamAuthority {
    /// @notice Returned if the `AtomicManualParty` is created with no members
    error NoPartyMembers();
    /// @notice Returned if the lengths of `partyMembers` and `partyMemberVotingPowers` do not match
    error ArityMismatch();
    /// @notice Returned if a party card would be issued to the null address
    error InvalidPartyMember();
    /// @notice Returned if a party card would be issued with no voting power
    error InvalidPartyMemberVotingPower();
    /// @notice Returned if a party card would be issued to a user who already has a party card
    error UserAlreadyHasPartyCard();
    /// @notice Returned if the caller is not authorized to perform the action
    error NotAuthorized();
    /// @notice Returned if no Hypersub is set for the party
    error NoHypersubSet();

    /// @notice Emitted when a party card is added via the `AddPartyCardsAuthority`

    /// @notice Emitted when a new party card is added to a party
    /// @param party The address of the party to which the card was added
    /// @param partyMember The address of the member who received the new party card
    /// @param newIntrinsicVotingPower The voting power assigned to the new party card
    event PartyCardAdded(address indexed party, address indexed partyMember, uint96 newIntrinsicVotingPower);
    /// @notice Emitted when a Hypersub is set for a party
    event HypersubSet(address indexed party, address indexed hypersub);

    /// @notice Mapping of party addresses to their corresponding Hypersub addresses
    mapping(address => address payable) public partyToHypersub;

    /// @notice Atomically distributes new party cards and updates the total voting power as needed.
    /// @dev Caller must be the party and this contract must be an authority on the party
    /// @param party The address of the party to add cards to
    /// @param newPartyMembers Addresses of the new party members (duplicates allowed)
    /// @param newPartyMemberVotingPowers Voting powers for the new party cards
    /// @param initialDelegates Initial delegates for the new party members. If the member already set a delegate this is ignored.
    function addPartyCards(
        address party,
        address[] calldata newPartyMembers,
        uint96[] calldata newPartyMemberVotingPowers,
        address[] calldata initialDelegates
    ) external {
        uint256 newPartyMembersLength = newPartyMembers.length;
        if (newPartyMembersLength == 0) {
            revert NoPartyMembers();
        }
        if (
            newPartyMembersLength != newPartyMemberVotingPowers.length
                || newPartyMembersLength != initialDelegates.length
        ) {
            revert ArityMismatch();
        }

        address payable hypersubAddress = partyToHypersub[party];
        if (hypersubAddress == address(0)) {
            revert NoHypersubSet();
        }

        uint96 addedVotingPower;
        for (uint256 i; i < newPartyMembersLength; ++i) {
            if (newPartyMemberVotingPowers[i] == 0) {
                revert InvalidPartyMemberVotingPower();
            }
            if (newPartyMembers[i] == address(0)) {
                revert InvalidPartyMember();
            }
            // Check if the user has an active Hypersub subscription
            require(
                SubscriptionTokenV1(hypersubAddress).balanceOf(newPartyMembers[i]) > 0,
                "User does not have an active Hypersub subscription"
            );
            addedVotingPower += newPartyMemberVotingPowers[i];
        }
        Party(payable(party)).increaseTotalVotingPower(addedVotingPower);

        for (uint256 i; i < newPartyMembersLength; ++i) {
            mint(party, newPartyMembers[i], newPartyMemberVotingPowers[i], initialDelegates[i]);
        }
    }

    /// @dev Modifier to check if the user doesn't already have a Party Card
    modifier onlyNonMembers(address party, address newPartyMember) {
        if (PartyGovernanceNFT(party).balanceOf(newPartyMember) > 0) {
            revert UserAlreadyHasPartyCard();
        }
        _;
    }

    /// @dev Internal function to mint a new party card
    /// @param party The address of the party
    /// @param newPartyMember The address of the new party member
    /// @param newPartyMemberVotingPower The voting power for the new party card
    /// @param initialDelegate The initial delegate for the new party member
    function mint(address party, address newPartyMember, uint96 newPartyMemberVotingPower, address initialDelegate)
        internal
        onlyNonMembers(party, newPartyMember)
    {
        PartyGovernanceNFT(party).mint(newPartyMember, newPartyMemberVotingPower, initialDelegate);
        emit PartyCardAdded(party, newPartyMember, newPartyMemberVotingPower);
    }

    /// @notice Sets the Hypersub address for a given party
    /// @param party The address of the party
    /// @param hypersub The address of the Hypersub
    function setHypersub(address party, address payable hypersub) external onlyHosts(party) {
        partyToHypersub[party] = hypersub;
        emit HypersubSet(party, hypersub);
    }

    /// @dev Modifier to check if the caller is a host of the party
    modifier onlyHosts(address party) {
        if (!Party(payable(party)).isHost(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }
}
