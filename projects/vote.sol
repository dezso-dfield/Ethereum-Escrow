// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Voting {
    address[] private owners;

    uint256 private constant MIN_YES_VOTES = 10;

    struct Proposal {
        address target;
        bytes data;
        uint yesCount;
        uint noCount;
        bool executed;
    }

    enum VoteStatus {
        NoVote,
        Yes,
        No
    }

    Proposal[] public proposals;
    mapping(uint => mapping(address => VoteStatus)) private voterStatus;

    event ProposalCreated(uint _id);
    event VoteCast(uint _id, address _voter);
    event ProposalExecuted(uint _id);

    constructor(address[] memory _addresses) {
        owners.push(msg.sender);
        for (uint i = 0; i < _addresses.length; i++) {
            owners.push(_addresses[i]);
        }
    }

    modifier onlyOwner() {
        bool isOwner = false;
        for (uint i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Not an authorized owner");
        _;
    }

    function newProposal(address _addy, bytes calldata _bytes) external onlyOwner {
        Proposal memory proposal;
        proposal.target = _addy;
        proposal.data = _bytes;
        proposal.yesCount = 0;
        proposal.noCount = 0;
        proposal.executed = false;
        proposals.push(proposal);
        emit ProposalCreated(proposals.length - 1);
    }

    function castVote(uint _id, bool _vote) external onlyOwner {
        require(_id < proposals.length, "Invalid proposal ID");
        require(!proposals[_id].executed, "Proposal already executed");

        VoteStatus currentVote = voterStatus[_id][msg.sender];
        VoteStatus newVoteStatus = _vote ? VoteStatus.Yes : VoteStatus.No;

        if (currentVote != newVoteStatus) {
            if (currentVote == VoteStatus.NoVote) {
                if (_vote) {
                    proposals[_id].yesCount += 1;
                } else {
                    proposals[_id].noCount += 1;
                }
            } else if (currentVote == VoteStatus.Yes && !_vote) {
                proposals[_id].yesCount -= 1;
                proposals[_id].noCount += 1;
            } else if (currentVote == VoteStatus.No && _vote) {
                proposals[_id].noCount -= 1;
                proposals[_id].yesCount += 1;
            }

            voterStatus[_id][msg.sender] = newVoteStatus;
            emit VoteCast(_id, msg.sender);

            if (_vote && proposals[_id].yesCount >= MIN_YES_VOTES) {
                proposals[_id].executed = true; 
                
                (bool success, ) = proposals[_id].target.call(proposals[_id].data);
                require(success, "Proposal execution failed");
                
                emit ProposalExecuted(_id);
            }
        }
    }

    function getVoterStatus(uint _id, address _voter) public view returns (VoteStatus) {
        return voterStatus[_id][_voter];
    }
}
