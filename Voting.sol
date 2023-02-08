// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol"; 

contract Voting is Ownable {

    function isContractAdmin() public view onlyOwner returns(bool) {
        return msg.sender == owner();
    }

}
