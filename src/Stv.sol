
pragma solidity ^0.8.13;

contract Stv {
    // Proposal object
    struct Proposal {
        bytes32 name; // Only allow names of 32 chars or less.
        uint256 voteCount;
    }

    // Voter object
    struct Voter {
        bool voted;
        uint weight;
        uint8 vote1; // Limit to at most 256 proposals, so use uint8.
        uint8 vote2;
        uint8 vote3;
    }

    // Public state 
    Proposal[] public proposals;
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
                voteCount: 0
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
    function vote(uint8[] calldata votes) external {
        if (votes.length > 3) revert SubmittedMoreThanThreeVotes();
        if (voters[msg.sender].weight == 0) revert SenderHasNoRightToVote();
        if (voters[msg.sender].voted) revert SenderAlreadyVoted();

        voters[msg.sender].voted = true;
        voters[msg.sender].vote1 = votes[0];
        voters[msg.sender].vote2 = votes[1];
        voters[msg.sender].vote3 = votes[2];
    }

    // Tally winners
    function tallyWinners() public view {
        if (msg.sender != chairperson) revert OnlyChairperson();
        // a lot of calculations here
    }

}
