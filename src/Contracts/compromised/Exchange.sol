// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

import {TrustfulOracle} from "./TrustfulOracle.sol";
import {DamnValuableNFT} from "../DamnValuableNFT.sol";

/**
 * @title Exchange
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract Exchange is ReentrancyGuard {
    using Address for address payable;

    DamnValuableNFT public immutable token;
    TrustfulOracle public immutable oracle;

    event TokenBought(address indexed buyer, uint256 tokenId, uint256 price);
    event TokenSold(address indexed seller, uint256 tokenId, uint256 price);

    error NotEnoughETHInBalance();
    error AmountPaidIsNotEnough();
    error ValueMustBeGreaterThanZero();
    error SellerMustBeTheOwner();
    error SellerMustHaveApprovedTransfer();

    constructor(address oracleAddress) payable {
        token = new DamnValuableNFT(); //@audit can I call the token contract directly to somehow get the ETh
        oracle = TrustfulOracle(oracleAddress); //@audit can I somehow make a call to the oracle to make the price of ETH small so that I can buy the token and then sell it to the exchange for 999eth?
    }

    function buyOne() external payable nonReentrant returns (uint256) {
        uint256 amountPaidInWei = msg.value;
        if (amountPaidInWei == 0) revert ValueMustBeGreaterThanZero();
        // @audit can I modify how this median price is read? by interacting with the oracle contract? Interesting that its median?
        // Price should be in [wei / NFT]
        uint256 currentPriceInWei = oracle.getMedianPrice(token.symbol());
        if (amountPaidInWei < currentPriceInWei) revert AmountPaidIsNotEnough();

        uint256 tokenId = token.safeMint(msg.sender);

        payable(msg.sender).sendValue(amountPaidInWei - currentPriceInWei);

        emit TokenBought(msg.sender, tokenId, currentPriceInWei);

        return tokenId;
    }

    function sellOne(uint256 tokenId) external nonReentrant {
        if (msg.sender != token.ownerOf(tokenId)) revert SellerMustBeTheOwner();
        if (token.getApproved(tokenId) != address(this)) {
            revert SellerMustHaveApprovedTransfer();
        }

        // Price should be in [wei / NFT]
        uint256 currentPriceInWei = oracle.getMedianPrice(token.symbol());
        if (address(this).balance < currentPriceInWei) {
            revert NotEnoughETHInBalance();
        }

        token.transferFrom(msg.sender, address(this), tokenId);
        token.burn(tokenId);

        payable(msg.sender).sendValue(currentPriceInWei);

        emit TokenSold(msg.sender, tokenId, currentPriceInWei);
    }
    // @audit the contract can receive money. There is a potential bug here becuase the contract should have a way to withdraw if it receives money
    receive() external payable {}
}

/**
 * Attack Scenario
 * 1. X Gets median price of nfts, create a bunch of NFTs for a very low price, buy one for 1 wei, burn the NFT or modify the oracle so Median price increases, sell it to the exchage profit
 * 2. X Similar to scenario one but I may be able to just create a scam DNFT and then sell it for outragous price. I will be the owner of the nft as well 
 * 3. X DNFT is pretty secure for now. The only other gateway is the oracle contract. Can I modify the oracle call to buy a DNFT and then sell a DNFT 
 * 4. The oracle contract is pretty secure as well BUT we have another key piece of information ;) it appears that the information given from the http request is likely a private key of one or two of the oracles. IF so we can post prices on their behalf
 */