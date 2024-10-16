// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import {SetupPartyHelper} from "../utils/SetupPartyHelper.sol";
import {Party, PartyGovernance, PartyGovernanceNFT} from "@party/contracts/party/Party.sol";
import {ProposalExecutionEngine} from "@party/contracts/proposals/ProposalExecutionEngine.sol";
import {JoinFamAuthority} from "../../src/JoinFamAuthority.sol";
import {ArbitraryCallsProposal} from "@party/contracts/proposals/ArbitraryCallsProposal.sol";

contract JoinFamAuthorityTest is SetupPartyHelper {
    JoinFamAuthority authority;

    event PartyCardAdded(address indexed party, address indexed partyMember, uint96 newIntrinsicVotingPower);
    event HypersubSet(address indexed party, address indexed hypersub);

    constructor() SetupPartyHelper(false) {}

    function setUp() public override {
        super.setUp();

        authority = new JoinFamAuthority();

        // Add as authority to the Party to be able to mint cards
        vm.prank(address(party));
        party.addAuthority(address(authority));
    }

    function test_addPartyCards_single() public {
        address[] memory newPartyMembers = new address[](1);
        newPartyMembers[0] = _randomAddress();
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
        newPartyMembers[0] = _randomAddress();
        newPartyMembers[1] = _randomAddress();
        newPartyMembers[2] = _randomAddress();
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
        newPartyMembers[0] = newPartyMembers[1] = newPartyMembers[2] = _randomAddress();
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
        newPartyMembers[0] = _randomAddress();
        newPartyMembers[1] = _randomAddress();
        newPartyMembers[2] = _randomAddress();
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
        proposePassAndExecuteProposal(proposal);

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
        newPartyMembers[0] = _randomAddress();
        newPartyMembers[1] = _randomAddress();
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
        address hypersubAddress = _randomAddress();

        vm.prank(hosts[0]);
        authority.setHypersub(partyAddress, hypersubAddress);

        assertEq(authority.partyToHypersub(partyAddress), hypersubAddress);
    }

    function testSetHypersubEmitsEvent() public {
        address partyAddress = address(party);
        address hypersubAddress = _randomAddress();

        vm.expectEmit(true, true, false, false);
        emit HypersubSet(partyAddress, hypersubAddress);

        vm.prank(hosts[0]);
        authority.setHypersub(partyAddress, hypersubAddress);
    }

    function testSetHypersubOnlyAuthorized() public {
        address partyAddress = address(party);
        address hypersubAddress = _randomAddress();
        address unauthorizedUser = _randomAddress();

        vm.prank(unauthorizedUser);
        vm.expectRevert(JoinFamAuthority.NotAuthorized.selector);
        authority.setHypersub(partyAddress, hypersubAddress);
    }

    function testSetHypersubUpdateExisting() public {
        address partyAddress = address(party);
        address initialHypersubAddress = _randomAddress();
        address newHypersubAddress = _randomAddress();

        vm.prank(hosts[0]);
        authority.setHypersub(partyAddress, initialHypersubAddress);
        assertEq(authority.partyToHypersub(partyAddress), initialHypersubAddress);

        vm.prank(hosts[0]);
        authority.setHypersub(partyAddress, newHypersubAddress);
        assertEq(authority.partyToHypersub(partyAddress), newHypersubAddress);
    }
}
