// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Voting.sol";

contract VotingFactory {

   function create() public returns (address) {
       return address(new Voting());
   }
   
}
