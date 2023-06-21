// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
// TODO - create and import an interface for  DamnValuableTokenSnapshot, SelfiePool, and SimpleGovernance
// import ERC20 snapshot from oepnzeppelin 


import {ERC20Snapshot} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Snapshot.sol";
contract SelfieAttacker{

    ERC20Snapshot public dvt;
    //IDamnvValuableTokenSnapshot public governancToken
    // ISiimpleGovernance public simpleGovernance
    // ISelfiePool public selfiePool


    // constructor(_)

}

/**
 * POC For attack 
 * 1. Call the flashloan using a receiver in an setup Attack function 
 * 2. in the recieve function make a call to snapshot 
 * 3a. queue the action ( construct calldata that will call the drainfUnds funciton).
 * 3b in the receive function send the dvt tokens right back to the contract. this is possible because you don't have to deposit tokens to que an action 
 * 4. In the execute attack function we are going to call the SimpleGovernance execute Action.
 * 5. Send those tokens directly to the attacker
 */