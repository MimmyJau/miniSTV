// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Stv} from "../src/Stv.sol";

struct Voter {
    bool voted;
    uint256 weight;
    uint256[] votes; 
}

contract StvExample {
    address public chairperson;
    bytes[] public proposals;
    bool private _active;
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

        for (uint256 i = 0; i < proposals_.length; i++) {
            proposals.push(proposals_[i]);
        }
    }

    /// @notice Get the total number of proposals
    /// @dev Subtract one because index 0 is always empty
    /// @return The total number of proposals
    function numProposals() external view returns (uint256) {
        return proposals.length - 1;
    }

    /// @notice Give address the right to vote
    /// @param aspiringVoter Address of the user being granted the right to vote
    function suffrage(address aspiringVoter) external {
        require(msg.sender == chairperson);
        require(!_voters[aspiringVoter].voted);
        require(_voters[aspiringVoter].weight == 0);

        _voters[aspiringVoter].weight = 1;
    }

    /// @notice Opens voting, users cannot vote until this function is called
    function start() external {
        stv = new Stv(proposals.length);
        _active = true;
    }

    /// @notice Submit a vote
    /// @param vote_ A rank-order of votes
    function vote(uint256[] calldata vote_) external {
        require(_voters[msg.sender].weight > 0);
        require(!_voters[msg.sender].voted);
        require(vote_.length <= 3);
        require(_active);

        // add vote to vote tree
        stv.addVote(vote_);

        // add vote to voter's record
        uint256[] storage votes = _voters[msg.sender].votes;
        for (uint256 i = 0; i < vote_.length; i++) {
            votes.push(vote_[i]);
        }
        _voters[msg.sender].voted = true;
    }

    function getVote() external view returns (uint256[] memory votes) {
        return _voters[msg.sender].votes;
    }

    function end(uint256 numWinners) external returns (uint256[] memory winners_) {
        require(msg.sender == chairperson);
        require(_active);

        winners_ = stv.finalize(numWinners);
        for (uint256 i = 0; i < winners_.length; i++) {
            _winners.push(winners_[i]);
        }

        _active = false;

        return winners_;
    }

    function winners() external view returns (uint256[] memory winners_) {
        require(!_active);

        for (uint256 i = 0; i < _winners.length; i++) {
            winners_[i] = _winners[i];
        }

        return winners_;
    }

}
