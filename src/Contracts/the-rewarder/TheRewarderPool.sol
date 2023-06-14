// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {RewardToken} from "./RewardToken.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {AccountingToken} from "./AccountingToken.sol";

/**
 * @title TheRewarderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TheRewarderPool {
    // Minimum duration of each round of rewards in seconds
    uint256 private constant REWARDS_ROUND_MIN_DURATION = 5 days;

    uint256 public lastSnapshotIdForRewards;
    uint256 public lastRecordedSnapshotTimestamp;

    mapping(address => uint256) public lastRewardTimestamps;

    // Token deposited into the pool by users
    DamnValuableToken public immutable liquidityToken;

    // Token used for internal accounting and snapshots
    // Pegged 1:1 with the liquidity token
    AccountingToken public accToken;

    // Token in which rewards are issued
    RewardToken public immutable rewardToken;

    // Track number of rounds
    uint256 public roundNumber;

    error MustDepositTokens();
    error TransferFail();

    constructor(address tokenAddress) {
        // Assuming all three tokens have 18 decimals
        liquidityToken = DamnValuableToken(tokenAddress);
        accToken = new AccountingToken();
        rewardToken = new RewardToken();

        _recordSnapshot();
    }

    /**
     * @notice sender must have approved `amountToDeposit` liquidity tokens in advance
     */ // @note it appears anyone can deposit and the tokens don't get "locked" here...Flashloan in /out then receive rewards
    function deposit(uint256 amountToDeposit) external {
        if (amountToDeposit == 0) revert MustDepositTokens();
        // @note credits the msg.sender accounting tokens 1:1 of DVT tokens
        accToken.mint(msg.sender, amountToDeposit); //@audit anyone can deposit 
        distributeRewards(); // @audit Source/Step 1 - call deposit() with flashloaned amount
        //@note if the transferFrom returns false, then revert
        if (!liquidityToken.transferFrom(msg.sender, address(this), amountToDeposit)) revert TransferFail();
    }
    //@audit-issue There is no limitations around withdrawals? I can flashloan dvt, deposit dvt here, withdraw dvt from here.
    function withdraw(uint256 amountToWithdraw) external {
        accToken.burn(msg.sender, amountToWithdraw); 
        if (!liquidityToken.transfer(msg.sender, amountToWithdraw)) { //@audit sink / Step 2: withdraw doposited tokens 
            revert TransferFail();
        }
    }
    // @note it appears every time someone deposits tokens within a round, they will receive a rewards. 
    function distributeRewards() public returns (uint256) {
        uint256 rewards = 0;
        // @note if we are in the next round ( block.now >= (last timestamp + 5 days), record a snapshot 
        if (isNewRewardsRound()) {
            _recordSnapshot();  // @audit I can use the logic, that the snapshot is recorded with data, but the actual amount of dvt the  rewarder pull has for me will be empty
        }

        uint256 totalDeposits =  accToken.totalSupplyAt(lastSnapshotIdForRewards); //@note grabs the total amount of deposits 
        uint256 amountDeposited = accToken.balanceOfAt(msg.sender, lastSnapshotIdForRewards); // @note gets the balaance of amount deposits by msg.sender

        if (amountDeposited > 0 && totalDeposits > 0) {
            rewards = (amountDeposited * 100 * 10 ** 18) / totalDeposits;
            // @note checks that they haven't retrived a reward for this round
            if (rewards > 0 && !_hasRetrievedReward(msg.sender)) {
                rewardToken.mint(msg.sender, rewards); 
                lastRewardTimestamps[msg.sender] = block.timestamp;
            }
        }

        return rewards;
    }

    function _recordSnapshot() private {
        lastSnapshotIdForRewards = accToken.snapshot();
        lastRecordedSnapshotTimestamp = block.timestamp;
        roundNumber++;
    }

    function _hasRetrievedReward(address account) private view returns (bool) {
        return (
            lastRewardTimestamps[account] >= lastRecordedSnapshotTimestamp // @note returns false if a user hasn't claimed a reward since the last snapshop
                && lastRewardTimestamps[account] <= lastRecordedSnapshotTimestamp + REWARDS_ROUND_MIN_DURATION
        );
    }

    function isNewRewardsRound() public view returns (bool) {
        return block.timestamp >= lastRecordedSnapshotTimestamp + REWARDS_ROUND_MIN_DURATION;
    }
}
