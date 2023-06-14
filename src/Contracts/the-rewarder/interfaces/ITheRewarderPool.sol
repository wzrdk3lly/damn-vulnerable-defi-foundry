// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITheRewarderPool{
    
    function deposit(uint256 amountToDeposit) external ;
    
    function withdraw(uint256 amountToWithdraw) external ;

    function distributeRewards() external returns (uint256);

}