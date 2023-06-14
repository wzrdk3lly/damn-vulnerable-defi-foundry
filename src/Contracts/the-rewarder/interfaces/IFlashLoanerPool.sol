// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
interface IFlashLoanerPool{
        function flashLoan(uint256 amount) external;

}