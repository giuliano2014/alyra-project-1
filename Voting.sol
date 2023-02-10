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

    // Mapping that stores a voter's state relative to their address in the whitelist
    mapping (address => Voter) whitelist;

    uint256 private votingCount;
    uint256 private whitelistedCount;
    uint256 private winningProposalId;
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
     * Add a proposal
     * @dev Only the Whitelisted person can call this function
     * @param _proposal the proposal description
     */
    function addProposal(string memory _proposal) public onlyWhitelisted isProposalsRegistrationStarted("Right now, you can't add voting proposal") {
        proposals.push(Proposal(_proposal, 0));
        emit ProposalRegistered(proposals.length);
    }

    function findTheWinningProposalId() public onlyOwner {
        require(votingStatus == WorkflowStatus.VotingSessionEnded, "Right now, you can't find the winning proposal ID");
        uint256 maxVoteCount = 0;
        uint256 maxVoteCountIndex = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxVoteCount) {
                maxVoteCount = proposals[i].voteCount;
                maxVoteCountIndex = i;
            }
        }
        winningProposalId = maxVoteCountIndex;
        votingStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, votingStatus);
    }

    /**
     * Get the state of voter
     * @dev Only the owner can call this function
     * @param _address the address to check
     * @return Voter
     */
    /*function getTheStateOfTheVoter(address _address) public view onlyOwner returns(Voter memory) {
        return whitelist[_address];
    }*/

    function getVoterVoteByAddress(address _address) public view onlyWhitelisted isVotesTallied returns(string memory) {
        uint256 proposalId = whitelist[_address].votedProposalId;
        return proposals[proposalId].description;
    } 

    function getWinner() public view isVotesTallied returns(string memory) {
        return proposals[winningProposalId].description;
    }

    /**
     * Check if an address is in the whitelist
     * @dev Only the owner can call this function
     * @param _address the address to check
     * @return bool indicating if the address is in the whitelist or not
     */
    /*function isWhitelisted(address _address) public view onlyOwner returns(bool) {
        return whitelist[_address].isRegistered;
    }*/

    /**
     * Add an address to the whitelist
     * @dev Only the owner can call this function
     * @param _address the address to add to the whitelist
     */
    function setWhitelist(address _address) public onlyOwner isRegisteringVoters("It's too late to register new voters") {
        require(!whitelist[_address].isRegistered, "This address already exits");
        whitelist[_address].isRegistered = true;
        whitelistedCount++;
        emit VoterRegistered(_address);
    }

    function startProposalSession() public onlyOwner isRegisteringVoters("Right now, you can't start proposal session") {
        require(whitelistedCount >= 2, "There are not enough subscribers in the whitelist");
        votingStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, votingStatus);
    }

    function startVotingSession() public onlyOwner {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationEnded, "Right now, you can't start voting session");
        votingStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, votingStatus);
    }

    function stopProposalSession() public onlyOwner isProposalsRegistrationStarted("Right now, you can't stop proposal session") {
        require(proposals.length >= 2, "At least, 2 proposals are required");
        votingStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, votingStatus);
    }

    function stopVotingSession() public onlyOwner isVotingSessionStarted("Right now, you can't stop voting session") {
        require(whitelistedCount == votingCount, "Not all voters have voted yet");
        votingStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, votingStatus);
    }

    function voting(uint8 _proposalNumber) public onlyWhitelisted isVotingSessionStarted("Right now, you can't vote") {
        require(!whitelist[msg.sender].hasVoted, "You have already voted");
        proposals[_proposalNumber].voteCount++;
        whitelist[msg.sender].hasVoted = true;
        whitelist[msg.sender].votedProposalId = _proposalNumber;
        votingCount++;
        emit Voted(msg.sender, _proposalNumber);
    }

}
