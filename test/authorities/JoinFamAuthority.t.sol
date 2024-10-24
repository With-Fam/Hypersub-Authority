// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SetupPartyHelper} from "../utils/SetupPartyHelper.sol";
import {Party, PartyGovernance, PartyGovernanceNFT} from "@party/contracts/party/Party.sol";
import {ProposalExecutionEngine} from "@party/contracts/proposals/ProposalExecutionEngine.sol";
import {JoinFamAuthority} from "../../src/JoinFamAuthority.sol";
import {ArbitraryCallsProposal} from "@party/contracts/proposals/ArbitraryCallsProposal.sol";
import {SubscriptionTokenV1Factory} from "../../src/hypersub/SubscriptionTokenV1Factory.sol";
import {SubscriptionTokenV1} from "../../src/hypersub/SubscriptionTokenV1.sol";
import {Shared} from "../../src/hypersub/Shared.sol";

contract JoinFamAuthorityTest is SetupPartyHelper {
    JoinFamAuthority authority;
    address subscriber;
    address subscriberTwo;
    address subscriberThree;

    event PartyCardAdded(address indexed party, address indexed partyMember, uint96 newIntrinsicVotingPower);
    event HypersubSet(address indexed party, address indexed hypersub);

    SubscriptionTokenV1 hypersub;
    SubscriptionTokenV1Factory hypersubFactory;

    constructor() SetupPartyHelper(false) {}

    function setUp() public override {
        super.setUp();

        authority = new JoinFamAuthority();

        // Add as authority to the Party to be able to mint cards
        vm.prank(address(party));
        party.addAuthority(address(authority));

        // Deploy a mock Hypersub contract
        SubscriptionTokenV1 implementation = new SubscriptionTokenV1();
        hypersubFactory = new SubscriptionTokenV1Factory(address(implementation));

        // Deploy a new subscription contract
        hypersub = SubscriptionTokenV1(
            payable(
                hypersubFactory.deploySubscription{value: 0}(
                    "Test Subscription",
                    "TEST",
                    "https://example.com/contract",
                    "https://example.com/token/",
                    1e18, // 1 token per second
                    3600, // 1 hour minimum
                    1000, // 10% rewards
                    address(0), // Use native token
                    0 // Use default fee config
                )
            )
        );

        subscriber = _randomAddress();
        subscriberTwo = _randomAddress();
        subscriberThree = _randomAddress();
        address[] memory accounts = new address[](3);
        accounts[0] = subscriber;
        accounts[1] = subscriberTwo;
        accounts[2] = subscriberThree;
        hypersub.grantTime(accounts, 333);

        vm.prank(hosts[0]);
        authority.setHypersub(address(party), payable(address(hypersub)));
    }

    function test_addPartyCards_single() public {
        address[] memory newPartyMembers = new address[](1);
        newPartyMembers[0] = subscriber;
        uint96[] memory newPartyMemberVotingPowers = new uint96[](1);
        newPartyMemberVotingPowers[0] = 100;
        address[] memory initialDelegates = new address[](1);
        initialDelegates[0] = _randomAddress();

        uint96 totalVotingPowerBefore = party.getGovernanceValues().totalVotingPower;

        vm.prank(address(party));
        authority.addPartyCards(address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates);

        assertEq(party.getGovernanceValues().totalVotingPower - totalVotingPowerBefore, newPartyMemberVotingPowers[0]);
        assertEq(party.votingPowerByTokenId(party.tokenCount()), newPartyMemberVotingPowers[0]);
        assertEq(party.getVotingPowerAt(initialDelegates[0], uint40(block.timestamp), 0), newPartyMemberVotingPowers[0]);
        assertEq(party.delegationsByVoter(newPartyMembers[0]), initialDelegates[0]);
    }

    function test_addPartyCards_multiple() public {
        address[] memory newPartyMembers = new address[](3);
        newPartyMembers[0] = subscriber;
        newPartyMembers[1] = subscriberTwo;
        newPartyMembers[2] = subscriberThree;
        uint96[] memory newPartyMemberVotingPowers = new uint96[](3);
        newPartyMemberVotingPowers[0] = 100;
        newPartyMemberVotingPowers[1] = 200;
        newPartyMemberVotingPowers[2] = 300;
        address[] memory initialDelegates = new address[](3);

        uint96 totalVotingPowerBefore = party.getGovernanceValues().totalVotingPower;
        uint96 tokenCount = party.tokenCount();

        vm.expectEmit(true, true, true, true);
        emit PartyCardAdded(address(party), newPartyMembers[0], newPartyMemberVotingPowers[0]);
        vm.expectEmit(true, true, true, true);
        emit PartyCardAdded(address(party), newPartyMembers[1], newPartyMemberVotingPowers[1]);
        vm.expectEmit(true, true, true, true);
        emit PartyCardAdded(address(party), newPartyMembers[2], newPartyMemberVotingPowers[2]);
        vm.prank(address(party));
        authority.addPartyCards(address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates);

        uint96 totalVotingPowerAdded;
        for (uint256 i; i < newPartyMembers.length; i++) {
            uint256 tokenId = tokenCount + i + 1;

            totalVotingPowerAdded += newPartyMemberVotingPowers[i];

            assertEq(party.votingPowerByTokenId(tokenId), newPartyMemberVotingPowers[i]);
            assertEq(
                party.getVotingPowerAt(newPartyMembers[i], uint40(block.timestamp), 0), newPartyMemberVotingPowers[i]
            );
        }
        assertEq(party.getGovernanceValues().totalVotingPower - totalVotingPowerBefore, totalVotingPowerAdded);
    }

    function test_addPartyCards_multipleWithSameAddress() public {
        address[] memory newPartyMembers = new address[](3);
        newPartyMembers[0] = newPartyMembers[1] = newPartyMembers[2] = subscriber;
        uint96[] memory newPartyMemberVotingPowers = new uint96[](3);
        newPartyMemberVotingPowers[0] = 100;
        newPartyMemberVotingPowers[1] = 200;
        newPartyMemberVotingPowers[2] = 300;
        address[] memory initialDelegates = new address[](3);
        initialDelegates[0] = _randomAddress();
        initialDelegates[1] = _randomAddress();
        initialDelegates[2] = _randomAddress();

        uint96 totalVotingPowerBefore = party.getGovernanceValues().totalVotingPower;
        uint96 tokenCount = party.tokenCount();

        vm.expectRevert(JoinFamAuthority.UserAlreadyHasPartyCard.selector);
        authority.addPartyCards(address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates);

        // Check that no party cards were added
        assertEq(party.getGovernanceValues().totalVotingPower - totalVotingPowerBefore, 0);
        assertEq(party.tokenCount() - tokenCount, 0);
    }

    function test_addPartyCard_cannotAddNoPartyCards() public {
        address[] memory newPartyMembers;
        uint96[] memory newPartyMemberVotingPowers;
        address[] memory initialDelegates;

        vm.expectRevert(JoinFamAuthority.NoPartyMembers.selector);
        authority.addPartyCards(address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates);
    }

    function test_addPartyCard_cannotAddZeroVotingPower() public {
        address[] memory newPartyMembers = new address[](1);
        newPartyMembers[0] = _randomAddress();
        uint96[] memory newPartyMemberVotingPowers = new uint96[](1);
        newPartyMemberVotingPowers[0] = 0;
        address[] memory initialDelegates = new address[](1);
        initialDelegates[0] = _randomAddress();

        vm.expectRevert(JoinFamAuthority.InvalidPartyMemberVotingPower.selector);
        authority.addPartyCards(address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates);
    }

    function test_addPartyCard_arityMismatch() public {
        address[] memory newPartyMembers = new address[](2);
        newPartyMembers[0] = newPartyMembers[1] = _randomAddress();
        uint96[] memory newPartyMemberVotingPowers = new uint96[](1);
        newPartyMemberVotingPowers[0] = 0;
        address[] memory initialDelegates = new address[](1);
        initialDelegates[0] = _randomAddress();

        vm.expectRevert(JoinFamAuthority.ArityMismatch.selector);
        authority.addPartyCards(address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates);
    }

    function test_addPartyCard_integration() public {
        // Propose proposal to call `addPartyCards` with 3 new members
        address[] memory newPartyMembers = new address[](3);
        newPartyMembers[0] = subscriber;
        newPartyMembers[1] = subscriberTwo;
        newPartyMembers[2] = subscriberThree;
        uint96[] memory newPartyMemberVotingPowers = new uint96[](3);
        newPartyMemberVotingPowers[0] = 100;
        newPartyMemberVotingPowers[1] = 200;
        newPartyMemberVotingPowers[2] = 300;
        address[] memory initialDelegates = new address[](3);

        ArbitraryCallsProposal.ArbitraryCall[] memory calls = new ArbitraryCallsProposal.ArbitraryCall[](1);
        calls[0] = ArbitraryCallsProposal.ArbitraryCall({
            target: payable(address(authority)),
            value: 0,
            data: abi.encodeCall(
                JoinFamAuthority.addPartyCards,
                (address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates)
            ),
            expectedResultHash: bytes32(0)
        });

        PartyGovernance.Proposal memory proposal = PartyGovernance.Proposal({
            maxExecutableTime: uint40(type(uint40).max),
            cancelDelay: 0,
            proposalData: abi.encodeWithSelector(bytes4(uint32(ProposalExecutionEngine.ProposalType.ArbitraryCalls)), calls)
        });

        uint96 totalVotingPowerBefore = party.getGovernanceValues().totalVotingPower;
        uint96 tokenCount = party.tokenCount();

        // Propose and execute
        emit log_uint(hypersub.balanceOf(subscriber));
        emit log_uint(hypersub.balanceOf(subscriberTwo));
        emit log_uint(hypersub.balanceOf(subscriberThree));
        emit log_address(subscriber);
        emit log_address(subscriberTwo);
        emit log_address(subscriberThree);
        _proposePassAndExecuteProposal(proposal);

        // Check that the new members were added and the total voting power was updated
        uint96 totalVotingPowerAdded;
        for (uint256 i; i < newPartyMembers.length; i++) {
            uint256 tokenId = tokenCount + i + 1;

            totalVotingPowerAdded += newPartyMemberVotingPowers[i];

            assertEq(party.votingPowerByTokenId(tokenId), newPartyMemberVotingPowers[i]);
            assertEq(
                party.getVotingPowerAt(newPartyMembers[i], uint40(block.timestamp), 0), newPartyMemberVotingPowers[i]
            );
        }
        assertEq(party.getGovernanceValues().totalVotingPower - totalVotingPowerBefore, totalVotingPowerAdded);
    }

    function test_addPartyCards_userAlreadyHasPartyCard() public {
        address[] memory newPartyMembers = new address[](2);
        newPartyMembers[0] = subscriber;
        newPartyMembers[1] = subscriberTwo;
        uint96[] memory newPartyMemberVotingPowers = new uint96[](2);
        newPartyMemberVotingPowers[0] = 100;
        newPartyMemberVotingPowers[1] = 200;
        address[] memory initialDelegates = new address[](2);
        initialDelegates[0] = _randomAddress();
        initialDelegates[1] = _randomAddress();

        // Mint the first Party Card
        authority.addPartyCards(address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates);

        // Try to add Party Cards to the existing members
        vm.expectRevert(JoinFamAuthority.UserAlreadyHasPartyCard.selector);
        authority.addPartyCards(address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates);

        // Verify that only the initially minted Party Card exists
        assertEq(party.balanceOf(newPartyMembers[0]), 1);
        assertEq(party.balanceOf(newPartyMembers[1]), 1);
    }

    function testSetHypersub() public {
        address partyAddress = address(party);
        address payable hypersubAddress = _randomAddress();

        vm.prank(hosts[0]);
        authority.setHypersub(partyAddress, hypersubAddress);

        assertEq(authority.partyToHypersub(partyAddress), hypersubAddress);
    }

    function testSetHypersubEmitsEvent() public {
        address partyAddress = address(party);
        address payable hypersubAddress = _randomAddress();

        vm.expectEmit(true, true, false, false);
        emit HypersubSet(partyAddress, hypersubAddress);

        vm.prank(hosts[0]);
        authority.setHypersub(partyAddress, hypersubAddress);
    }

    function testSetHypersubOnlyAuthorized() public {
        address partyAddress = address(party);
        address payable hypersubAddress = _randomAddress();
        address unauthorizedUser = _randomAddress();

        vm.prank(unauthorizedUser);
        vm.expectRevert(JoinFamAuthority.NotAuthorized.selector);
        authority.setHypersub(partyAddress, hypersubAddress);
    }

    function testSetHypersubUpdateExisting() public {
        address partyAddress = address(party);
        address payable initialHypersubAddress = _randomAddress();
        address payable newHypersubAddress = _randomAddress();

        vm.prank(hosts[0]);
        authority.setHypersub(partyAddress, initialHypersubAddress);
        assertEq(authority.partyToHypersub(partyAddress), initialHypersubAddress);

        vm.prank(hosts[0]);
        authority.setHypersub(partyAddress, newHypersubAddress);
        assertEq(authority.partyToHypersub(partyAddress), newHypersubAddress);
    }

    function test_addPartyCards_requiresActiveHypersubSubscription() public {
        address user = _randomAddress();
        address[] memory newPartyMembers = new address[](1);
        newPartyMembers[0] = user;
        uint96[] memory newPartyMemberVotingPowers = new uint96[](1);
        newPartyMemberVotingPowers[0] = 100;
        address[] memory initialDelegates = new address[](1);
        initialDelegates[0] = _randomAddress();

        // Set the Hypersub address for the party
        vm.prank(hosts[0]);
        authority.setHypersub(address(party), payable(address(hypersub)));

        // Try to add party card without an active subscription
        vm.expectRevert(JoinFamAuthority.NoActiveSubscription.selector);
        vm.prank(address(party));
        authority.addPartyCards(address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates);

        // Simulate an active subscription by setting a non-zero balance
        vm.mockCall(
            address(hypersub), abi.encodeWithSelector(SubscriptionTokenV1.balanceOf.selector, user), abi.encode(1)
        );

        // Now the addition should succeed
        vm.prank(address(party));
        authority.addPartyCards(address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates);

        // Verify that the party card was added
        assertEq(party.balanceOf(user), 1);
    }

    function test_addPartyCards_requiresHypersubSet() public {
        address[] memory newPartyMembers = new address[](1);
        newPartyMembers[0] = subscriber;
        uint96[] memory newPartyMemberVotingPowers = new uint96[](1);
        newPartyMemberVotingPowers[0] = 100;
        address[] memory initialDelegates = new address[](1);
        initialDelegates[0] = _randomAddress();

        vm.prank(hosts[0]);
        authority.setHypersub(address(party), payable(address(0)));

        // Try to add party cards without setting a Hypersub
        vm.expectRevert(JoinFamAuthority.NoHypersubSet.selector);
        vm.prank(address(party));
        authority.addPartyCards(address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates);

        // Set the Hypersub for the new party
        vm.prank(hosts[0]);
        authority.setHypersub(address(party), payable(address(hypersub)));

        // Now the addition should succeed
        vm.prank(address(party));
        authority.addPartyCards(address(party), newPartyMembers, newPartyMemberVotingPowers, initialDelegates);

        // Verify that the party card was added
        assertEq(party.balanceOf(subscriber), 1);
    }
}
