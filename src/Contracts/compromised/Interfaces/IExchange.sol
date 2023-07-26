// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

 interface IExchange{
     function buyOne() payable external returns (uint256);
     function sellOne(uint256 tokenId) external;
 }
