// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import {Party} from "@party/contracts/party/Party.sol";
import {PartyGovernanceNFT} from "@party/contracts/party/PartyGovernanceNFT.sol";
import {SubscriptionTokenV1} from "./hypersub/SubscriptionTokenV1.sol";

contract ManageFamAuthority {
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
    /// @notice Returned if a user doesn't have an active Hypersub subscription
    error NoActiveSubscription();
    /// @notice Returned if no token IDs are provided for removal
    error NoTokenIds();
    /// @notice Returned if the user still has an active subscription
    error ActiveSubscription();

    /// @notice Emitted when a party card is added via the `AddPartyCardsAuthority`

    /// @notice Emitted when a new party card is added to a party
    /// @param party The address of the party to which the card was added
    /// @param partyMember The address of the member who received the new party card
    /// @param newIntrinsicVotingPower The voting power assigned to the new party card
    event PartyCardAdded(
        address indexed party,
        address indexed partyMember,
        uint96 newIntrinsicVotingPower
    );
    /// @notice Emitted when a Hypersub is set for a party
    event HypersubSet(address indexed party, address indexed hypersub);
    /// @notice Emitted when a party card is removed from a party
    /// @param party The address of the party from which the card was removed
    /// @param tokenId The ID of the removed party card
    event PartyCardRemoved(address indexed party, uint256 indexed tokenId);

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
            newPartyMembersLength != newPartyMemberVotingPowers.length ||
            newPartyMembersLength != initialDelegates.length
        ) {
            revert ArityMismatch();
        }

        uint96 addedVotingPower;
        for (uint256 i; i < newPartyMembersLength; ++i) {
            if (newPartyMemberVotingPowers[i] == 0) {
                revert InvalidPartyMemberVotingPower();
            }
            if (newPartyMembers[i] == address(0)) {
                revert InvalidPartyMember();
            }

            addedVotingPower += newPartyMemberVotingPowers[i];
        }
        Party(payable(party)).increaseTotalVotingPower(addedVotingPower);

        for (uint256 i; i < newPartyMembersLength; ++i) {
            mint(
                party,
                newPartyMembers[i],
                newPartyMemberVotingPowers[i],
                initialDelegates[i]
            );
        }
    }

    /// @dev Modifier to check if the user doesn't already have a Party Card
    /// @param party The address of the party
    /// @param newPartyMember The address of the new party member
    /// @notice Reverts if the new party member already has a party card
    modifier onlyNonMembers(address party, address newPartyMember) {
        if (PartyGovernanceNFT(party).balanceOf(newPartyMember) > 0) {
            revert UserAlreadyHasPartyCard();
        }
        _;
    }

    /// @dev Modifier to check if the party has a Hypersub set
    /// @param party The address of the party
    /// @notice Reverts if no Hypersub is set for the party
    modifier onlyHypersubParties(address party) {
        if (partyToHypersub[party] == address(0)) {
            revert NoHypersubSet();
        }
        _;
    }

    /// @dev Modifier to check if the user has an active subscription
    /// @param party The address of the party
    /// @param subscriber The address of the subscriber
    /// @notice Reverts if the subscriber does not have an active subscription
    modifier onlySubscribed(address party, address subscriber) {
        address payable hypersubAddress = partyToHypersub[party];
        if (SubscriptionTokenV1(hypersubAddress).balanceOf(subscriber) == 0) {
            revert NoActiveSubscription();
        }
        _;
    }

    /// @dev Modifier to check if the user does not have an active subscription
    /// @param party The address of the party
    /// @param hypersubAddress The address of the Hypersub
    /// @param tokenId The ID of the party card
    /// @notice Reverts if the owner of the token still has an active subscription
    modifier onlyUnsubscribed(
        address party,
        address hypersubAddress,
        uint256 tokenId
    ) {
        address owner = PartyGovernanceNFT(party).ownerOf(tokenId);
        if (
            SubscriptionTokenV1(payable(hypersubAddress)).balanceOf(owner) > 0
        ) {
            revert ActiveSubscription();
        }
        _;
    }

    /// @dev Internal function to mint a new party card
    function mint(
        address party,
        address newPartyMember,
        uint96 newPartyMemberVotingPower,
        address initialDelegate
    )
        internal
        onlyNonMembers(party, newPartyMember)
        onlyHypersubParties(party)
        onlySubscribed(party, newPartyMember)
    {
        PartyGovernanceNFT(party).mint(
            newPartyMember,
            newPartyMemberVotingPower,
            initialDelegate
        );
        emit PartyCardAdded(party, newPartyMember, newPartyMemberVotingPower);
    }

    /// @notice Sets the Hypersub address for a given party
    /// @param party The address of the party
    /// @param hypersub The address of the Hypersub
    function setHypersub(
        address party,
        address payable hypersub
    ) external onlyHosts(party) {
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

    /// @notice Removes party cards from members with expired subscriptions
    /// @param party The address of the party to remove cards from
    /// @param tokenIds The IDs of the party cards to remove
    function removePartyCards(
        address party,
        uint256[] calldata tokenIds
    ) external {
        if (tokenIds.length == 0) {
            revert NoTokenIds();
        }

        address payable hypersubAddress = partyToHypersub[party];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            burn(party, tokenIds[i], hypersubAddress);
        }
    }

    /// @dev Internal function to burn a party card
    /// @param party The address of the party
    /// @param tokenId The ID of the party card to burn
    /// @param hypersubAddress The address of the Hypersub
    function burn(
        address party,
        uint256 tokenId,
        address payable hypersubAddress
    )
        internal
        onlyHypersubParties(party)
        onlyUnsubscribed(party, hypersubAddress, tokenId)
    {
        PartyGovernanceNFT(party).burn(tokenId);
        emit PartyCardRemoved(party, tokenId);
    }
}
