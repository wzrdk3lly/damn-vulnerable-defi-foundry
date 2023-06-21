// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {ERC20Snapshot} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {SimpleGovernance} from "./SimpleGovernance.sol";

/**
 * @title SelfiePool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SelfiePool is ReentrancyGuard {
    using Address for address;

    ERC20Snapshot public token;
    SimpleGovernance public governance;

    event FundsDrained(address indexed receiver, uint256 amount);

    error OnlyGovernanceAllowed();
    error NotEnoughTokensInPool();
    error BorrowerMustBeAContract();
    error FlashLoanHasNotBeenPaidBack();
    //@note anything with this moddifier can only be called by the governance contract
    modifier onlyGovernance() {
        if (msg.sender != address(governance)) revert OnlyGovernanceAllowed();
        _;
    }
    // @note the ERC20 snaphshot and SimpleGovernanace aren't intialized here  
    constructor(address tokenAddress, address governanceAddress) {
        token = ERC20Snapshot(tokenAddress);
        governance = SimpleGovernance(governanceAddress);
    }
    // @note anyone can take a flashloan  so long as the sender is a contract. 
    function flashLoan(uint256 borrowAmount) external nonReentrant {
        uint256 balanceBefore = token.balanceOf(address(this));
        if (balanceBefore < borrowAmount) revert NotEnoughTokensInPool();

        token.transfer(msg.sender, borrowAmount);

        if (!msg.sender.isContract()) revert BorrowerMustBeAContract();
        msg.sender.functionCall(abi.encodeWithSignature("receiveTokens(address,uint256)", address(token), borrowAmount));

        uint256 balanceAfter = token.balanceOf(address(this));

        if (balanceAfter < balanceBefore) revert FlashLoanHasNotBeenPaidBack();
    }
    //@note in our attack contract we need to make a proxy call via the governanace contract to call the drain all funds function
    function drainAllFunds(address receiver) external onlyGovernance {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(receiver, amount);

        emit FundsDrained(receiver, amount);
    }
}
