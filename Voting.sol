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

    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    mapping (address => Voter) whitelist;

    uint private votingCount;
    uint private whitelistedCount;
    uint private winningProposalId;
    Proposal[] public proposals;
    WorkflowStatus private votingStatus;

    modifier isProposalsRegistrationStarted(string memory _error) {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationStarted, _error);
        _;
    }

    modifier isRegisteringVoters(string memory _error) {
        require(votingStatus == WorkflowStatus.RegisteringVoters, _error);
        _;
    }

    modifier isVotesTallied() {
        require(votingStatus == WorkflowStatus.VotesTallied, "The counting of the votes has not yet been done");
        _;
    }

    modifier isVotingSessionStarted(string memory _error) {
        require(votingStatus == WorkflowStatus.VotingSessionStarted, _error);
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender].isRegistered, "You are not authorized");
        _;
    }

    /**
     * Add a proposal for voting
     * @dev Only whitelisted can call this function
     * @param _proposal the proposal description
     */
    function addProposal(string calldata _proposal) external onlyWhitelisted isProposalsRegistrationStarted("Right now, you can't add voting proposal") {
        proposals.push(Proposal(_proposal, 0));
        emit ProposalRegistered(proposals.length);
    }

    /**
     * This function determines the winning proposal ID by finding the proposal with the most votes
     * @dev Only the owner can call this function
     */
    function findTheWinningProposalId() external onlyOwner {
        // Check if the voting session has ended
        require(votingStatus == WorkflowStatus.VotingSessionEnded, "Right now, you can't find the winning proposal ID");

        // Initialize variables to keep track of the proposal with the most votes
        uint maxVoteCount = 0;
        uint maxVoteCountIndex = 0;

        // Loop through all proposals to find the one with the most votes
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxVoteCount) {
                maxVoteCount = proposals[i].voteCount;
                maxVoteCountIndex = i;
            }
        }

        // Set the winning proposal ID
        winningProposalId = maxVoteCountIndex;

        // Update the voting status
        votingStatus = WorkflowStatus.VotesTallied;

        // Emit an event indicating that the voting status has changed
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, votingStatus);
    }

    /**
     * Retrieve the vote made by a voter with a specific address
     * @dev Only whitelisted can call this function
     * @param _address the address of the voter whose vote
     * @return The description of the proposal that the voter voted for
     */
    function getVoterVoteByAddress(address _address) external view onlyWhitelisted isVotesTallied returns(string memory) {
        uint proposalId = whitelist[_address].votedProposalId;
        return proposals[proposalId].description;
    } 

    function getWinner() external view isVotesTallied returns(string memory) {
        return proposals[winningProposalId].description;
    }

    /**
     * Add an address to the whitelist
     * @dev Only the owner can call this function
     * @param _address the address to add to the whitelist
     */
    function setWhitelist(address _address) external onlyOwner isRegisteringVoters("It's too late to register new voters") {
        require(!whitelist[_address].isRegistered, "This address already exits");
        whitelist[_address].isRegistered = true;
        whitelistedCount++;
        emit VoterRegistered(_address);
    }

    function startProposalSession() external onlyOwner isRegisteringVoters("Right now, you can't start proposal session") {
        require(whitelistedCount >= 2, "There are not enough subscribers in the whitelist");
        votingStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, votingStatus);
    }

    function startVotingSession() external onlyOwner {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationEnded, "Right now, you can't start voting session");
        votingStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, votingStatus);
    }

    function stopProposalSession() external onlyOwner isProposalsRegistrationStarted("Right now, you can't stop proposal session") {
        require(proposals.length >= 2, "At least, 2 proposals are required");
        votingStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, votingStatus);
    }

    function stopVotingSession() external onlyOwner isVotingSessionStarted("Right now, you can't stop voting session") {
        require(whitelistedCount == votingCount, "Not all voters have voted yet");
        votingStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, votingStatus);
    }

    /**
     * This function allows a user to vote on a proposal
     * @dev Only whitelisted can call this function
     * @param _proposalNumber the proposal id
     */
    function voting(uint _proposalNumber) external onlyWhitelisted isVotingSessionStarted("Right now, you can't vote") {
        // Check if the sender has already voted
        require(!whitelist[msg.sender].hasVoted, "You have already voted");

        // Increase the vote count for the specified proposal
        proposals[_proposalNumber].voteCount++;

        // Mark the sender as having voted
        whitelist[msg.sender].hasVoted = true;
        whitelist[msg.sender].votedProposalId = _proposalNumber;

        // Increase the overall voting count
        votingCount++;

        // Emit an event indicating that the user has voted
        emit Voted(msg.sender, _proposalNumber);
    }

}
