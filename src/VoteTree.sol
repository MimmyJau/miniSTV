
import { Tree } from "../src/Tree.sol";

struct Node {
    uint256 proposal;
    uint256 votes;
    uint256 cumulativeVotes;
}

contract RankVoteTree is Tree {
    bytes32 private root;
    mapping(bytes32 => Node) public tree;

    constructor() {
        // TODO: limit on how many rankings?
        root = super.getRoot();
    }

    // Check if a proposal is already a child of another Node.
    function isChild(bytes32 parent, uint256 proposal) private view returns (bool, bytes32) {
        bytes32[] memory children = getChildren(parent);
        for (uint i = 0; i < children.length; i++) {
            if (tree[children[i]].proposal == proposal) {
                return (true, children[i]);
            }
        }
        return (false, parent);
    }

    function addChild(bytes32 parent, uint256 proposal) private returns (bytes32) {
        bytes32 child = super.addChild(parent);
        tree[child].proposal = proposal;
        return child;
    }

    function addRanking(uint256[] calldata ranking) private {
        bytes32 parent = root;
        for (uint i = 0; i < ranking.length; i++) {
            (bool childExists, bytes32 child) = isChild(parent, ranking[i]);
            if (!childExists) {
                child = addChild(parent, ranking[i]);
            } 
            parent = child;
        }
    }

    // Add Vote
    function addVote(uint256[] calldata ranking) public {
        // bytes32 parent = root;
        // for (uint256 i = 0; i < ranking.length; i++) {
        //     bytes32 child = super.addChild(parent);
        //     tree[child].proposal = ranking[i];
        //     parent = child;
        // }
    }

    // Get Relevant Rankings
    function getRankingsWithProposals() public {}
}
