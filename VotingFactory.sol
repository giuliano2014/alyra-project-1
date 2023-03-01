// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Voting.sol";

contract VotingFactory {

    Voting public voting;

    // mapping to store an array of voting contract addresses, keyed by client ID
    mapping(string => address[]) private votingContractsByClientId;

    /**
     * Creates a new instance of the Voting contract and stores its address in the
     * votingContractsByClientId mapping under the given client ID.
     *
     * @param _clientId the client ID to associate with the new contract instance
     * @return the address of the newly created contract instance
     */
    function create(string calldata _clientId) public returns (address) {
        // create a new instance of the Voting contract
        address newVotingContract = address(new Voting());
        // store the address of the new instance in the mapping, under the given client ID
        votingContractsByClientId[_clientId].push(newVotingContract);
        // return the address of the new contract instance
        return newVotingContract;
    }

    function getVotingContractsByClientId(string calldata _clientId) public view returns (address[] memory) {
        return votingContractsByClientId[_clientId];
    }

}
