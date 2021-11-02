// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./Tradingcredits.sol";

import "./uniswap/IUniswapV2Router02.sol";
import "./uniswap/IUniswapV2Factory.sol";
import "./IERC20.sol";
import "./Registry.sol";

contract Broker is Ownable {

    IUniswapV2Router02 public pancake_router =
        IUniswapV2Router02(Registry.PANCAKE_ROUTER_ADDRESS);

    uint256 public totalUSDtraded;

    constructor() {
    }
    
    function depositBUSD(uint256 qtyIn) public returns (uint256) {
         //= 1 * 10**18;

        //need approve from msgsender to this contract
        require(IERC20(Registry.BUSD).transferFrom(msg.sender, address(this), qtyIn), "Broker: transfer to broker failed");
    }

    function withdrawBUSD(uint256 amount) public {

        require(IERC20(Registry.BUSD).transfer(msg.sender, amount), "Broker: withdraw margin failed");
    }

    function withdrawToken(uint256 amount) public {

        //require(IERC20(Registry.BUSD).transfer(msg.sender, amount), "Broker: withdraw margin failed");
    }

    function allowRouter(uint256 qtyIn) public returns (uint256) {
        //uint256 qtyIn = 1 * 10**18;

        IERC20(Registry.BUSD).approve(Registry.PANCAKE_ROUTER_ADDRESS, qtyIn);
    }

    function tradeCake(uint256 qtyIn) public returns (uint256) {
        address token = Registry.CAKE;
        //uint256 qtyIn = 1 * 10**18;
        uint256 amountOutmin = 0; //1 * 10**18;
        address[] memory route = new address[](2);
        route[0] = Registry.BUSD;
        route[1] = token;
        uint256 deadline = block.timestamp + 15 minutes;
        uint256[] memory amounts = pancake_router.swapExactTokensForTokens(
            qtyIn,
            amountOutmin,
            route,
            msg.sender,
            deadline
        );


        totalUSDtraded += qtyIn;

        return amounts[0];
    }

}

