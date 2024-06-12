// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
 // Create an interface for the selfiePoolAttack
// Create a nn interface for SimpleGovernance
// create an interface for IERC20Snapshot


contract SelfiePoolAttack{

    // Create an setUpAttack function that calls the selfiePool

    // create a receiveTokens(address,uint256) functions that calls DVTsnapshot to appear as if I have 1 million dvt

    // Create a valid governance action that will be qued and then executed. I can have it call the pool's drain fund balance

    // call the eecuteAttack function which calls the SimpleGovernance contract to execute an action 

}

// Steps of POC 
/**
 * 1. take flashloan of DVT 
 * 2. call DVTsnapshot snapshot() function to take a snapshot and make me appear as if I have more than qurom votes
 * 3. Que an action in the governance contract that has data that calls the lending pool's drain all funds function
 * 4. return the DVT to the lending pools 
 * 5. Call the execute action 
 */

