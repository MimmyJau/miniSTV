# miniSTV

This is a minimal implementation of [single-transferable voting](https://en.wikipedia.org/wiki/Single_transferable_vote) (STV), a rank-order voting system aiming to be fairer than the traditional [first-past-the-post voting](https://en.wikipedia.org/wiki/First-past-the-post_voting) system. 

## Background

The advantages of STV are manyfold:
- It can be used for both single-winner ([instant-runoff](https://en.wikipedia.org/wiki/Instant-runoff_voting)) or multi-winner elections,
- It minimizes "wasted" votes, since your vote can be transferred to another candidate you've ranked if your preferred candidate is either eliminated or elected,
- By minimizing wasted votes, it disincentives strategic voting, thus encouraging voters to state their actual preferences,
- In a multi-winner election, the use of a quota in STV ensures that the proportion of winners roughly mirrors the proportion of votes.


For more detailed information see the following wikipedia articles:
- [Single transferable vote](https://en.wikipedia.org/wiki/Single_transferable_vote)
- [Counting single transferable votes](https://en.wikipedia.org/wiki/Counting_single_transferable_votes)
- [Ranked voting](https://en.wikipedia.org/wiki/Ranked_voting)
- [Instant-runoff voting](https://en.wikipedia.org/wiki/Instant-runoff_voting)
- [First-past-the-post](https://en.wikipedia.org/wiki/First-past-the-post_voting)

## Local Environment

This project was built using [Foundry](https://github.com/foundry-rs/foundry). 

To run tests, call `forge test`.

## Limitations / TODOs

Gas cost is very high for submitting a vote.

The tiebreaking process in each round of counting involves a three-step procedure. 
1) Initially, it considers who had the most (or least) first-rank votes in the initial tally. 
2) Next, it evaluates who had the most (or least) votes in the most recent tally before the current tie. 
3) Finally, it considers which proposal was submitted first (or last) by the vote's owner. 

This last step should be replaced with a random number generator (RNG) function for improved fairness. Additionally, we can use all tallies in chronological order rather than just the first and last tallies.

If for whatever reason, not enough candidates surpass the quota to be elected, the program will not warn you in advance, and will instead close the vote and only return the number of candidates that surpassed the quota. This situation should only occur in when there are very few votes.

Currently, the implementation only supports the [Droop quota](https://en.wikipedia.org/wiki/Droop_quota) method for calculating the required votes for a candidate to be elected. Future versions may include alternative quota calculation methods.
