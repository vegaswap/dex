// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Registry.sol";
import "./uniswap/IUniswapV2Router02.sol";
import "./uniswap/IUniswapV2Factory.sol";

contract PriceEffect {

    //get price in USD

    IUniswapV2Router02 public pancake_router =
        IUniswapV2Router02(Registry.PANCAKE_ROUTER);

    function getBUSDPrice(address A, uint256 amount)
        public
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = Registry.USDC;
        path[1] = A;
        uint256 p = pancake_router.getAmountsIn(amount, path)[0];
        return p;
    }

    
}