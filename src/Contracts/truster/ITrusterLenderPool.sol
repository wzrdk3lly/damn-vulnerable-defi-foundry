// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITrusterLenderPool{
    function flashLoan (uint256, address, address , bytes calldata) external;
}