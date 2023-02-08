// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol"; 

contract Voting is Ownable {

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    // Mapping to store the state of the address in the whitelist
    mapping (address => bool) whitelist;

    WorkflowStatus public votingStatus;
    Proposal[] public proposals;

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "You are not authorized");
        _;
    }

    /**
     * Add an address to the whitelist
     * @dev Only the owner can call this function
     * @param _address the address to add to the whitelist
     */
    function setWhitelist(address _address) public onlyOwner {
        require(votingStatus == WorkflowStatus.RegisteringVoters, "Voting is already launched");
        whitelist[_address] = true;
    }

    /**
     * Check if an address is in the whitelist
     * @dev Only the owner can call this function
     * @param _address the address to check
     * @return bool indicating if the address is in the whitelist or not
     */
    function isWhitelisted(address _address) public view onlyOwner returns(bool) {
        return whitelist[_address];
    }

    function getVotingStatus() public view returns(WorkflowStatus) {
        return votingStatus;
    }

    function startProposalSession() public onlyOwner {
        votingStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    /**
     * Add a proposal
     * @dev Only the Whitelisted person can call this function
     * @param _proposal the proposal description
     */
    function addProposal(string memory _proposal) public onlyWhitelisted {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationStarted, "Voting is not yet launched");
        proposals.push(Proposal(_proposal, 0));
    }

}
