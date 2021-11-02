// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./Tradingcredits.sol";

import "./uniswap/IUniswapV2Router02.sol";
import "./uniswap/IUniswapV2Factory.sol";
import "./IERC20.sol";
import "./Registry.sol";

//track volume per account
//track total volume

/// Vega Broker routes to pools of liquidity
/// issues credits based on USD volume
contract BrokerOld is Ownable {
    Tradingcredits private tradingcredits;

    bool public IsInitialized;

    //uint256 private redeemedWeek;

    event Initialized();
    event Trade(address trader, uint256 amount);
    event TradeFail(address trade);

    event StringFailure(string stringFailure);

    struct Credit {
        address creditAddress;
        uint256 creditAmount;
        bool isAdded;
    }

    //IUniswapV2Factory public pancake_factory = IUniswapV2Factory(Registry.PANCAKE_FACTORY);

    IUniswapV2Router02 public pancake_router =
        IUniswapV2Router02(Registry.PANCAKE_ROUTER_ADDRESS);

    mapping(address => Credit) public credits;    

    constructor() {
        IsInitialized = true;
        emit Initialized();

        tradingcredits = new Tradingcredits("VCS");
    }
    

    //1 deposit to broker
    function depositBUSD() public returns (uint256) {
        uint256 qtyIn = 1 * 10**18;

        //need approve from msgsender to this contract
        require(IERC20(Registry.BUSD).transferFrom(msg.sender, address(this), qtyIn), "transfer to broker failed");
    }

    function allowRouter() public returns (uint256) {
        uint256 qtyIn = 1 * 10**18;

        IERC20(Registry.BUSD).approve(Registry.PANCAKE_ROUTER_ADDRESS, qtyIn);
    }


    //approve?
    //transferFrom
    

    function balanceRequired(uint256 qty, address token)
        public
        view
        returns (uint256)
    {
        uint256 price = getPriceBUSD(token, qty) / qty;
        uint256 amount_BUSD = qty * price;
        return amount_BUSD;
    }

    //TMP
    function tradeCake() public {

        //20 USD worth
        uint256 qty_in = 20 * 10**18;

        IERC20(Registry.BUSD).approve(Registry.PANCAKE_ROUTER_ADDRESS, qty_in);

        //uint allowed = IERC20(token1).allowance(address(this), address(sushiRouter));

        uint256 allowed = IERC20(Registry.BUSD).allowance(
            msg.sender,
            Registry.PANCAKE_ROUTER_ADDRESS
        );
        require(allowed >= qty_in, "not enough allowance to trade");

        uint256 amountOutmin = 0; //(qty*price)/2;
        address[] memory route = new address[](2);
        //in
        route[0] = Registry.BUSD;
        //out
        route[1] = Registry.CAKE;
        uint256 deadline = block.timestamp + 15 minutes;
        address recipient = msg.sender;
        uint256[] memory amounts;
        
        //https://docs.soliditylang.org/en/v0.8.5/control-structures.html?highlight=try#try-catch
        //try can only be used with external function calls
        try
            pancake_router.swapExactTokensForTokens(
                qty_in,
                amountOutmin,
                route,
                recipient,
                deadline
            )
        returns (uint256[] memory _amounts) {
            amounts = _amounts;
            
        } catch Error(string memory _err) {
            emit StringFailure(_err);
        }

        require(amounts[0] > 0, "no amount[0] traded");
        require(amounts[1] > 0, "no amount[1] traded");

        //TODO calculate USD amount
        uint256 price = 13;
        uint256 issue_amount = qty_in * price;

        tradingcredits.issue(msg.sender, issue_amount);

        // try credits.issue(msg.sender, issue_amount) {
        //     emit Trade(msg.sender, issue_amount);
        //     return (issue_amount, true);
        // } catch {
        //     emit TradeFail(msg.sender);
        //     return (0, false);
        // }
    }

    

    // returns (uint qty, bool success)
    //function trade(uint256 qty, address token) public {
    function tradeOld() public returns (uint256) {
        address token = Registry.CAKE;
        uint256 qtyIn = 1 * 10**18;

        //need approve from msgsender to this contract
        require(IERC20(Registry.BUSD).transferFrom(msg.sender, address(this), qtyIn), "transfer to broker failed");

        IERC20(Registry.BUSD).approve(Registry.PANCAKE_ROUTER_ADDRESS, qtyIn);

        //TODO X price
        // uint256 allowed = IERC20(Registry.BUSD).allowance(
        //     msg.sender,
        //     Registry.PANCAKE_ROUTER_ADDRESS
        // );
        // require(allowed >= qty, "not enough allowance to trade");
        //uint256 allowed = IERC20(BUSD).allowance(msg.sender, address(this));

        // uint256 dec = 18;
        // uint256 fdec = 10 ** dec;
        // uint256 qty = 5 * fdec;

        //assume linear, i.e. no price impact
        //TODO need more precision
        //uint256 price = getPriceBUSD(token, qtyIn) / qtyIn;

        //uint256 bal = IERC20(Registry.BUSD).balanceOf(msg.sender);
        //uint256 amount_BUSD = qtyIn * price;
        //require(bal >= amount_BUSD, "not enough balance to trade");

        //TODO slippage
        //uint256 amountOutmin = (qty * price) / 2;
        //qty/2
        uint256 amountOutmin = 0; //1 * 10**18;
        //require(amountOutmin > 0, ")
        address[] memory route = new address[](2);
        //trade against BUSD
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
        require(amounts[0] > 0, "no amount[0] traded");
        require(amounts[1] > 0, "no amount[1] traded");

        return amounts[0];

        //TODO calculate USD amount
        //uint256 issue_amount = qty;
        //tradingcredits.issue(msg.sender, issue_amount);

        // try credits.issue(msg.sender, issue_amount) {
        //     emit Trade(msg.sender, issue_amount);
        //     return (issue_amount, true);
        // } catch {
        //     emit TradeFail(msg.sender);
        //     return (0, false);
        // }
    }

    function reedemCredits(uint256 amount) public {
        //!TODO
        // maxWeek
        
    }

    function issueCredit(address account, uint256 amount) public onlyOwner {
        tradingcredits.issue(account, amount);
    }

    function creditAddress() public view returns (address) {
        return address(tradingcredits);
    }

    function balanceOfCredits() public view returns (uint256) {
        return tradingcredits.balanceOf(msg.sender);
    }

    function totalCredits() public view returns (uint256) {
        return tradingcredits.totalSupply();
    }

    function balanceOfToken(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(msg.sender);
    }

    function allowedRouter(address token) public view returns (uint256) {
        uint256 allowed = IERC20(token).allowance(
            msg.sender,
            Registry.PANCAKE_ROUTER_ADDRESS
        );
        return allowed;
    }

    function getPriceA(
        address A,
        address B,
        uint256 amount
    ) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = A;
        path[1] = B;
        return getPrice(path, amount);        
    }

    function getPrice(address[] memory path, uint256 amount) public view returns (uint256) {      
        uint256 p = pancake_router.getAmountsIn(amount, path)[0];
        return p;
    }

    function getPriceBNB(
        address A,        
        uint256 amount
    ) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = Registry.WBNB;        
        path[1] = A;
        return getPrice(path, amount);        
    }

    function getPriceBUSD(address A, uint256 amount)
        public
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = Registry.BUSD;        
        path[1] = A;
        return getPrice(path, amount);
    }

    // function depositBUSD(uint256 amount) public {

    //     //require (ERC20(Registry.BUSD).allowance(msg.sender, address(this)) >= amount,"BoostPool: not enough allowance");
    //     //require (ERC20(Registry.BUSD).balanceOf(msg.sender) >= amount,"BoostPool: not enough balance");
    //     require(IERC20(Registry.BUSD).transferFrom(msg.sender, address(this), amount), "Broker: deposit margin failed");

    //     credits[msg.sender] = Credit(
    //     {
    //         creditAddress: msg.sender,
    //         creditAmount: amount,            
    //         isAdded: true
    //     });  

    // }

    // function withdrawBUSD(uint256 amount) public {
    //     //TODO check credit of the msg.sender
    //     require(credits[msg.sender].creditAmount >= amount, "Broker: not enough credit");

    //     require(IERC20(Registry.BUSD).transfer(msg.sender, amount), "Broker: withdraw margin failed");
    // }

    // function setPair() public {
    //     select_pair[0] = WBNB;
    //     select_pair[1] = CAKE;
    // }
}


/////////
// misc code for trading on router

//TODO
        //factory address
        //https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Factory.sol#L10
        //getPair

        //find pair address
        //call swap()
        //https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Pair.sol#L159




// contract Arbitrage {
    
//     IUniswapV2Router02 public sushiRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    
//     event test (uint timestamp, uint amountIn, uint amountOut, address[] path, uint allowance, address sender);
    
//     function swapper(address token1, address token2) public  {
//         address[] memory path = new address[](2);
//         path[0] = token1;
//         path[1] = token2;
//         uint amountOut = 1 ether;
//         uint amountIn = sushiRouter.getAmountsIn(
//             amountOut,
//             path
//         )[0];
        
        
        
//         IERC20(token1).approve(address(sushiRouter), amountIn);
        
//         uint allowed = IERC20(token1).allowance(msg.sender, address(sushiRouter));
        
//         emit test(now+90, amountIn, amountOut, path, allowed, msg.sender);

//         sushiRouter.swapExactTokensForTokens(
//             amountIn, 
//             amountOut,
//             path, 
//             msg.sender, 
//             now + 60
//         );
//     }
// }

// address[] memory path = new address[](2);
// path[0] = tokenIn;
// path[1] = tokenOut;

// router.swapExactTokensForTokens(
//     amountIn,
//     0, // amountOutMin: we can skip computing this number because the math is tested
//     path,
//     to,
//     deadline
// );

//TODO check balance
//
//caller_balance = token.balanceOf(msg.sender);
//require(caller_balance>trademount)

//function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
//address pairAddress = IUniswapV2Factory(factory).getPair(token0, token1);
// require(pairAddress != 0, 'pool is not existed');
// IUniswapV2Pair(pairAddress).swap(amount0, amount1, address(this), bytes('not empty'));

//amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
//require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');

//uint256 price = 12;

// uint amountOut = 1 ether;
// uint amountIn = uniRouter.getAmountsIn(
//     amountOut,
//     path
// )[0];

//TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
//TransferHelper.safeApprove(tokenIn, address(router), amountIn);


