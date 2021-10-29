// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//Boost Pool
//a pool for fixed duration staking rewards

import "./erc20.sol";

contract BoostPool {

    address public owner;

    address public stakeToken;
    address public yieldToken;
    uint256 public startTime;
    uint256 public endTime;
    //uint256 public duration; // how long to stake, fixed in time at start of the pool
    uint256 public stakeDecimals;
    uint256 public yieldDecimals;
    uint256 public yieldTotal; //total of yield promised
    uint256 public maxPerStake;
    uint256 public maxYield;
    uint256 public maxStake;
    uint256 public totalAmountStaked;
    uint256 public currentStep;
    
    uint256[] public rewardSteps;
    uint256[] public stakeSteps;
    uint256 public rewardQuote;
    uint256 public minPerStake;

    event Deposit(uint256 amount);
    event StakeAdded(address stakeAddress, uint256 stakeAmount, uint256 stakeTime);
    event Unstaked(address stakeAddress, uint256 stakeAmount,uint256 yieldAmount);
    event OwnerDeposit(uint256 amount);
    event OwnerWithdraw(uint256 amount);
    
    struct Stake {
        address stakeAddress;
        uint256 stakeAmount;
        uint256 stakeTime;
        uint256 yieldAmount;
        bool isAdded;
        bool staked;
    }
    
    address[] public staker_addresses;
    mapping(address => Stake) public stakes;

    constructor(
        address _stakeToken,
        address _yieldToken,
        uint256 _duration,
        uint256 _maxYield,
        uint256 _maxStake,
        uint256 _stakeDecimals,
        uint256 _yieldDecimals,
        uint256 _maxPerStake,
        uint256 _minPerStake,
        uint256[] memory _rewardSteps,
        uint256[] memory _stakeSteps
    ){
        owner = msg.sender;
        //assert _stakeToken != ZERO_ADDRESS, "BoostPool: Vegatoken is zero address"
        stakeToken = _stakeToken;
        yieldToken = _yieldToken;
        maxYield = _maxYield;
        maxStake = _maxStake;
        minPerStake = _minPerStake;
        stakeDecimals = _stakeDecimals;
        yieldDecimals = _yieldDecimals;
        maxPerStake = _maxPerStake;        
        rewardSteps = _rewardSteps;        
        stakeSteps = _stakeSteps;  

        startTime = block.timestamp;
        endTime = startTime + _duration;

        totalAmountStaked = 0;
        currentStep = 0;
        rewardQuote = 1;        
        yieldTotal = 0;

    }    

    function stake(uint256 _stakeAmount) public {

        require(block.timestamp < endTime, "BoostPool: ended");
        require(block.timestamp >= startTime, "BoostPool: not started");
        require(_stakeAmount <= maxPerStake, "BoostPool: more than maximum stake");
        require(_stakeAmount >= minPerStake, "BoostPool: not enough");
        require(totalAmountStaked + _stakeAmount <= maxStake,  "BoostPool: maximum staked");
        require(!stakes[msg.sender].isAdded, "BoostPool: can only stake once");

        uint256 bal = ERC20(stakeToken).balanceOf(msg.sender);

        uint256 unclaimed = bal - totalAmountStaked;
        require(unclaimed >= _stakeAmount, "BoostPool: need the tokens to stake");

        // # assert self.rewardQuote > 0, "BoostPool: reward quote can not be 0"

        uint256 _yieldAmount = _stakeAmount * rewardSteps[currentStep]/rewardQuote;

        require(yieldTotal + _yieldAmount <= maxYield, "BoostPool: rewards exhausted");
        
        require(ERC20(stakeToken).transferFrom(msg.sender, address(this), _stakeAmount),"BoostPool: transfer failed");
        staker_addresses.push(msg.sender);

        stakes[msg.sender] = Stake(
        {
            stakeAddress: msg.sender,
            stakeAmount: _stakeAmount,
            stakeTime: block.timestamp,
            yieldAmount: _yieldAmount,
            isAdded: true,
            staked: true
        });    

        totalAmountStaked += _stakeAmount;

        if (totalAmountStaked > stakeSteps[currentStep]){
            currentStep++;
        }

        emit StakeAdded(msg.sender, _stakeAmount, block.timestamp);

    }

    function unstake() public {

        require(stakes[msg.sender].isAdded, "BoostPool: not a stakeholder");
        //uint256 b = ERC20(stakeToken).balanceOf(msg.sender);
        require(stakes[msg.sender].staked, "BoostPool: not staked");

        //uint256 lockduration = block.timestamp - stakes[msg.sender].stakeTime;
        //uint256 lockdays = lockduration/1 days;
        //require(lockdays >= duration, "BoostPool: not locked for duration");
        
        require(block.timestamp >= endTime, "BoostPool: not locked for duration");

        //transfer stake
        bool transferStakeSuccess = ERC20(stakeToken).transfer(msg.sender, stakes[msg.sender].stakeAmount);
        require(transferStakeSuccess, "BoostPool: sending stake failed");
        //transfer yield
        bool transferYieldSuccess = ERC20(yieldToken).transfer(msg.sender, stakes[msg.sender].yieldAmount);
        require(transferYieldSuccess, "BoostPool: sending yield failed");

        stakes[msg.sender].staked = false;

        //totalAmountStaked -= stakes[msg.sender].stakeAmount;
        emit Unstaked(msg.sender, stakes[msg.sender].stakeAmount, stakes[msg.sender].yieldAmount);

    }
    
    function depositOwner(uint256 amount) public {
        require(msg.sender == owner, "not the owner");

        require (ERC20(yieldToken).allowance(msg.sender, address(this)) >= amount,"BoostPool: not enough allowance");
        require (ERC20(yieldToken).balanceOf(msg.sender) >= amount,"BoostPool: not enough balance");

        bool transferYieldSuccess = ERC20(yieldToken).transferFrom(msg.sender, address(this), amount);
        require(transferYieldSuccess, "BoostPool: sending yield failed");

        emit OwnerDeposit(amount);
    }

    function withdrawOwner(uint256 amount) public {
        require(msg.sender == owner, "not the owner");
        uint256 bucketbalance = ERC20(yieldToken).balanceOf(address(this));
        uint256 unclaimedbalance = bucketbalance - totalAmountStaked;
        require(amount <= unclaimedbalance, "BoostPool: can't withdraw staked amounts");

        bool transferYieldSuccess = ERC20(yieldToken).transfer(msg.sender, amount);
        require(transferYieldSuccess, "BoostPool: withdrawOwner");

        emit OwnerWithdraw(amount);
    }

}