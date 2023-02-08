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

    Proposal[] public proposals;
    WorkflowStatus public votingStatus;
    uint256 public whitelistCount;

    modifier isProposalsRegistrationStartedStatus(string memory _error) {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationStarted, _error);
        _;
    }

    modifier isRegisteringVotersStatus(string memory _error) {
        require(votingStatus == WorkflowStatus.RegisteringVoters, _error);
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "You are not authorized");
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
     * Check if an address is in the whitelist
     * @dev Only the owner can call this function
     * @param _address the address to check
     * @return bool indicating if the address is in the whitelist or not
     */
    function isWhitelisted(address _address) public view onlyOwner returns(bool) {
        return whitelist[_address];
    }

    /**
     * Add an address to the whitelist
     * @dev Only the owner can call this function
     * @param _address the address to add to the whitelist
     */
    function setWhitelist(address _address) public onlyOwner isRegisteringVotersStatus("It's too late to register new voters") {
        whitelist[_address] = true;
        whitelistCount++;
    }

    function startProposalSession() public onlyOwner isRegisteringVotersStatus("There are not enough subscribers in the whitelist") {
        require(whitelistCount >= 2, "There are not enough subscribers in the whitelist");
        votingStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function startVotingSession() public onlyOwner {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationEnded, "Right now, you can't start voting session");
        votingStatus = WorkflowStatus.VotingSessionStarted;
    }

    function stopProposalSession() public onlyOwner isProposalsRegistrationStartedStatus("Right now, you can't stop proposal session") {
        votingStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }

    function voting() public view onlyWhitelisted returns(string memory) {
        require(votingStatus == WorkflowStatus.VotingSessionStarted, "The vote session has not yet started");
        return "Vote session is starting";
    }

}
