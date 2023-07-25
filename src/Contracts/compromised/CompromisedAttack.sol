// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

contract CompromisedAttack{
    address internal ExchangeAddress;
    address internal owner;

    error NotOWner();

    modifier onlyOwner(){
        if(msg.sender != owner) revert NotOWner();
        _;
    }
    // constructor initializes exchange contract and ownr

    // function to buyDiscount 

    // function to sellProfit


    // function to withdraw eth to onlyOwner

}

/**
 * ATTACk Objective: 
 * Steal all the ETH available in the exchange 
 * 
 * Arhitecture details:
 * exchange is selling overpriced collectables of DVNFT at 999ETH 
 * 
 * Attack POC: 
 * 
 * Convert https request from hexadecimal and then from base64 to recieve the private key  using cyberchef (remove the 0x)
 * 
 * Use cast wallet address --private-key <private-key> to get the wallet address 
 * Priv key 1 = c678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9 = 0xe92401A4d3af5E446d93D11EEc806b1462b39D15
 * PRiv key 2 = 208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48 = 0x81A5D6E50C214044bE44cA0CB057fe119097850c
 * 
 * 1. Now we can post some faulty prices for the nft to the oracle using those keys
 * 2. Buy the nft at 1 wei 
 * 3. post the actual price for the nft 
 * 4. Sell the nft for 99 eth
 * Exploit complete
 */