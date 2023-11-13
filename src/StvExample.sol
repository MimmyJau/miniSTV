// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Stv} from "../src/Stv.sol";

uint256 constant NUM_WINNERS = 3;
uint256 constant NUM_RANKINGS = 3;

struct Voter {
    bool voted;
    uint256 weight;
    uint256[] votes; 
}

contract StvExample {
    address public chairperson;
    bytes[] public proposals;
    bool private _active;
    bool private _over;
    uint256[] private _winners;
    mapping(address => Voter) private _voters; 
    Stv stv;

    constructor() {
        chairperson = msg.sender;
        _voters[chairperson].weight = 1;
        proposals.push(""); // Reserve index 0 spot.
    }

    /// @notice Add a list of proposals, only owner has permission
    /// @dev No restriction on size of proposal
    /// @param proposals_ List of proposals in bytes
    function addProposals(bytes[] calldata proposals_) external {
        require(msg.sender == chairperson);
        require(!_active);
        require(!_over);

        for (uint256 i = 0; i < proposals_.length; i++) {
            proposals.push(proposals_[i]);
        }
    }

    /// @notice Get list of names of all proposals
    /// @return proposalNames A list of all the proposal names. Will always have length
    ///         numProposals() + 1, i.e. index 0 will be empty.
    function getProposalNames() external view returns (bytes[] memory proposalNames) {
        require(_voters[msg.sender].weight > 0);

        proposalNames = new bytes[](proposals.length);

        for (uint256 i = 0; i < proposals.length; i++) {
            proposalNames[i] = proposals[i];
        }

        return proposalNames;
    }

    /// @notice Get the total number of proposals
    /// @dev Subtract one because index 0 is always empty
    /// @return The total number of proposals
    function numProposals() public view returns (uint256) {
        return proposals.length - 1;
    }

    /// @notice Give address the right to vote
    /// @param aspiringVoter Address of the user being granted the right to vote
    function suffrage(address aspiringVoter) external {
        require(msg.sender == chairperson);
        require(!_voters[aspiringVoter].voted);
        require(_voters[aspiringVoter].weight == 0);
        require(!_over);

        _voters[aspiringVoter].weight = 1;
    }

    /// @notice Opens voting, users cannot vote until this function is called
    function start() external {
        require(msg.sender == chairperson);
        require(numProposals() > 0);
        require(!_active);
        require(!_over);

        stv = new Stv(numProposals(), NUM_WINNERS);
        _active = true;
    }

    /// @notice Submit a vote
    /// @param vote_ A rank-order of votes
    function vote(uint256[] calldata vote_) external {
        require(_voters[msg.sender].weight > 0);
        require(!_voters[msg.sender].voted);
        require(vote_.length <= NUM_RANKINGS);
        require(_active);
        require(!_over);

        // add vote to vote tree
        stv.addVote(vote_);

        // add vote to voter's record
        uint256[] storage votes = _voters[msg.sender].votes;
        for (uint256 i = 0; i < vote_.length; i++) {
            votes.push(vote_[i]);
        }
        _voters[msg.sender].voted = true;
    }

    /// @notice Retrieve user's vote, will return empty list if sender hasn't voted
    /// @return votes List of sender's vote ranking
    function getVote() external view returns (uint256[] memory votes) {
        return _voters[msg.sender].votes;
    }

    /// @notice Ends voting and tallies winners
    /// @return winners_ List of winners
    function end() external returns (uint256[] memory winners_) {
        require(msg.sender == chairperson);
        require(_active);

        winners_ = stv.finalize();
        for (uint256 i = 0; i < winners_.length; i++) {
            _winners.push(winners_[i]);
        }

        _active = false;
        _over = true;

        return winners_;
    }

    /// @notice Returns a list of winning proposals
    /// @dev Cannot be called until voting is over
    /// @return winners_ List of winning proposals
    function winners() external view returns (uint256[] memory winners_) {
        require(!_active);

        winners_ = new uint256[](_winners.length);

        for (uint256 i = 0; i < _winners.length; i++) {
            winners_[i] = _winners[i];
        }

        return winners_;
    }
}
