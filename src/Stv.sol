// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Tree} from "../src/Tree.sol";

// Possible options for proposal status
enum Status {
    Eliminated,
    Winner,
    Undecided
}

// Proposal object
struct Proposal {
    bytes32 name; // Only allow names of 32 chars or less.
    uint256 tally;
    Status status;
}

struct VoteTree {
    uint256 proposal;
    uint256 votes;
    uint256 cumulativeVotes;
}

// Voter object
struct Voter {
    bool voted;
    uint weight;
    uint8 vote1; // Limit to at most 256 proposals, so use uint8.
    uint8 vote2; // Might not actually need to hold this data in storage.
    uint8 vote3;
}


contract Stv is Tree {
    // Public state 
    Proposal[] public proposals;
    // mapping(bytes32 => VoteTree) public VoteTree;
    mapping(address => Voter) public voters; 
    address public chairperson;

    // Errors
    error OnlyChairperson();
    error SenderAlreadyHasRightToVote();
    error SenderAlreadyVoted();
    error SenderHasNoRightToVote();
    error SubmittedMoreThanThreeVotes();
    error TooManyProposals(uint256 size);

    // Proposal constructor
    constructor(bytes32[] memory proposalNames) {
        if (proposalNames.length > 256) revert TooManyProposals(proposalNames.length);

        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint8 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                tally: 0,
                status: Status.Undecided
            }));
        }
    }

    // Grant voting power
    function grantRightToVote(address aspiringVoter) public {
        if (msg.sender != chairperson) revert OnlyChairperson();
        // Q: Does indexing voters[aspiringVoter] each time cost more gas 
        //    vs. setting Voter messager voter = voters[aspiringVoter]?
        if (voters[aspiringVoter].voted) revert SenderAlreadyVoted();
        if (voters[aspiringVoter].weight != 0) revert SenderAlreadyHasRightToVote();

        voters[aspiringVoter].weight = 1;
    }

    // Vote
    // function vote(uint8[] calldata ballot) external {
    //     if (ballot.length > 3) revert SubmittedMoreThanThreeVotes();
    //     if (voters[msg.sender].weight == 0) revert SenderHasNoRightToVote();
    //     if (voters[msg.sender].voted) revert SenderAlreadyVoted();

    //     votes.push(Vote({
    //         voter: msg.sender,
    //         vote1: ballot[0],
    //         vote2: ballot[1],
    //         vote3: ballot[2]
    //     }));

    //     voters[msg.sender].voted = true;
    //     totalVotes += 1;
    // }

    // Calculate droop quote
    // function droopQuota() private view returns (uint256) {
    //     return (totalVotes - 1) / (proposals.length + 1) + 1; // Division rounds down to nearest int.
    // }

    // Tally winners
    // function tallyWinners() public view {
    //     if (msg.sender != chairperson) revert OnlyChairperson();

    //     uint256 quota = droopQuota();
    // }

}
