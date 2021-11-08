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

    //TODO check credits

    constructor() {
    }
    
    function depositMargin(uint256 qtyIn) public returns (uint256) {
        //need approve
        require(IERC20(Registry.BUSD).transferFrom(msg.sender, address(this), qtyIn), "Broker: transfer to broker failed");
    }

    function withdrawMargin(uint256 amount) public {

        require(IERC20(Registry.BUSD).transfer(msg.sender, amount), "Broker: withdraw margin failed");
    }

    function withdrawToken(uint256 amount, address token) public {

        require(IERC20(token).transfer(msg.sender, amount), "Broker: withdraw margin failed");
    }

    function allowRouter(uint256 qty) public returns (uint256) {        
        IERC20(Registry.BUSD).approve(Registry.PANCAKE_ROUTER_ADDRESS, qty);
    }

    function allowRouter(uint256 qtyIn, address token) public returns (uint256) {        
        IERC20(token).approve(Registry.PANCAKE_ROUTER_ADDRESS, qtyIn);
    }

    function tradeBuy(uint256 qtyIn, address token) public returns (uint256) {
        //address token = Registry.CAKE;
        //TODO calculate slippage
        //BUY
        uint256 amountOutmin = 0; //1 * 10**18;
        address[] memory route = new address[](2);
        route[0] = Registry.BUSD;
        route[1] = token;
        uint256 deadline = block.timestamp + 15 minutes;

        uint256[] memory amounts = pancake_router.swapExactTokensForTokens(
            qtyIn,
            amountOutmin,
            route,
            address(this),
            deadline
        );

        totalUSDtraded += qtyIn;

        return amounts[0];
    }

    function tradeSell(uint256 qtyIn, address token) public returns (uint256) {
        //address token = Registry.CAKE;
        //TODO calculate slippage
        //SELL
        uint256 amountOutmin = 0; //1 * 10**18;
        address[] memory route = new address[](2);
        route[0] = token;
        route[1] = Registry.BUSD;
        uint256 deadline = block.timestamp + 15 minutes;

        uint256[] memory amounts = pancake_router.swapExactTokensForTokens(
            qtyIn,
            amountOutmin,
            route,
            address(this),
            deadline
        );

        totalUSDtraded += qtyIn;

        return amounts[0];
    }

    function buyCake(uint256 qtyIn) public returns (uint256) {
        address token = Registry.CAKE;
        //TODO calculate slippage
        //BUY
        uint256 amountOutmin = 0; //1 * 10**18;
        address[] memory route = new address[](2);
        route[0] = Registry.BUSD;
        route[1] = token;
        uint256 deadline = block.timestamp + 15 minutes;

        uint256 a = tradeBuy(qtyIn, token);
        return a;
    }

    //list of supported tokens
    //evaluate in USD terms

}

