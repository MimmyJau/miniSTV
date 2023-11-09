// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {RankVote} from "../src/RankVote.sol";

// Voter object
// Might not have to hold vote in storage
struct Voter {
    bool voted;
    uint256 weight;
    uint256[] votes; 
}

contract Stv is RankVote {
    address public chairperson;
    bytes32[] public proposals;
    bool private _active;
    uint256[] private _winners;
    mapping(address => Voter) private _voters; 

    constructor(bytes32[] memory proposalNames) RankVote(proposalNames.length) {
        require(proposalNames.length < 256);

        chairperson = msg.sender;
        _voters[chairperson].weight = 1;

        for (uint8 i = 0; i < proposalNames.length; i++) {
            proposals.push(proposalNames[i]);
        }
    }

    function suffrage(address aspiringVoter) external {
        require(msg.sender == chairperson);
        require(!_voters[aspiringVoter].voted);
        require(_voters[aspiringVoter].weight == 0);
        require(_active);

        _voters[aspiringVoter].weight = 1;
    }

    function vote(uint256[] calldata vote_) external {
        require(_voters[msg.sender].weight > 0);
        require(!_voters[msg.sender].voted);
        require(vote_.length <= 3);
        require(_active);

        // add vote to vote tree
        addVote(vote_);

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

        winners_ = finalize(numWinners);
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
