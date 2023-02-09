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

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    // Mapping that stores a voter's state relative to their address in the whitelist
    mapping (address => Voter) whitelist;

    Proposal[] public proposals;
    WorkflowStatus public votingStatus;
    uint256 public whitelistedCount;
    uint256 public votingCount;

    modifier isProposalsRegistrationStartedStatus(string memory _error) {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationStarted, _error);
        _;
    }

    modifier isRegisteringVotersStatus(string memory _error) {
        require(votingStatus == WorkflowStatus.RegisteringVoters, _error);
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender].isRegistered, "You are not authorized");
        _;
    }

    /**
     * Add a proposal
     * @dev Only the Whitelisted person can call this function
     * @param _proposal the proposal description
     */
    function addProposal(string memory _proposal) public onlyWhitelisted isProposalsRegistrationStartedStatus("Right now, you can't add voting proposal") {
        proposals.push(Proposal(_proposal, 0));
    }

    /**
     * Get the state of voter
     * @dev Only the owner can call this function
     * @param _address the address to check
     * @return Voter
     */
    function getTheStateOfTheVoter(address _address) public view onlyOwner returns(Voter memory) {
        return whitelist[_address];
    }

    /**
     * Check if an address is in the whitelist
     * @dev Only the owner can call this function
     * @param _address the address to check
     * @return bool indicating if the address is in the whitelist or not
     */
    function isWhitelisted(address _address) public view onlyOwner returns(bool) {
        return whitelist[_address].isRegistered;
    }

    /**
     * Add an address to the whitelist
     * @dev Only the owner can call this function
     * @param _address the address to add to the whitelist
     */
    function setWhitelist(address _address) public onlyOwner isRegisteringVotersStatus("It's too late to register new voters") {
        whitelist[_address].isRegistered = true;
        whitelistedCount++;
    }

    function startProposalSession() public onlyOwner isRegisteringVotersStatus("There are not enough subscribers in the whitelist") {
        require(whitelistedCount >= 2, "There are not enough subscribers in the whitelist");
        votingStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function startVotingSession() public onlyOwner {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationEnded, "Right now, you can't start voting session");
        votingStatus = WorkflowStatus.VotingSessionStarted;
    }

    function stopProposalSession() public onlyOwner isProposalsRegistrationStartedStatus("Right now, you can't stop proposal session") {
        votingStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }

    function stopVotingSession() public onlyOwner {
        require(votingStatus == WorkflowStatus.VotingSessionStarted, "Right now, you can't stop voting session");
        require(whitelistedCount == votingCount, "Not all voters have voted yet");
        votingStatus = WorkflowStatus.VotingSessionEnded;
    }

    function voting(uint8 _proposalNumber) public onlyWhitelisted {
        require(votingStatus == WorkflowStatus.VotingSessionStarted, "The vote session has not yet started");
        require(!whitelist[msg.sender].hasVoted, "You have already voted");
        proposals[_proposalNumber].voteCount++;
        whitelist[msg.sender].hasVoted = true;
        whitelist[msg.sender].votedProposalId = _proposalNumber;
        votingCount++;
    }

}
