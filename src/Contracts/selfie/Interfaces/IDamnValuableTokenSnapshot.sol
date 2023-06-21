// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDamnValuableTokenSnapshot{
    function snapshot() external returns (uint256); // most important function to pull off attack
}