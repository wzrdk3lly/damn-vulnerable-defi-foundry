// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISelfiePool{

        function drainAllFunds(address receiver) external;

        function flashLoan(uint256 borrowAmount) external ; 

}