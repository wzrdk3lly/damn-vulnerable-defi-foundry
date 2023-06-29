/// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface ISimpleGovernance{
        function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
        function executeAction(uint256 actionId) external payable ;

}