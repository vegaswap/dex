// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./erc20.sol";

contract BoostPool {

    address public owner;

    address public stakeToken;
    address public yieldToken;
    uint256 public startTime;
    uint256 public endTime;
    // #in days
    // days: constant(uint256) = 86400
    uint256 public duration;

    uint256 public stakeDecimals;
    uint256 public yieldDecimals;
    // #total number of yield promised
    uint256 public yieldTotal;
    uint256 public maxPerStake;
    uint256 public maxYield;
    uint256 public maxStake;
    uint256 public totalAmountStaked;
    //bool public stakingActive;
    // # reward
    uint256 public currentStep;
    uint256 public currentReward;
    uint256[] public rewardSteps;
    uint256[] public stakeSteps;
    uint256 public rewardQuote;
    // uint256 minPerStake

    event Deposit(uint256 amount);
    event StakeAdded(address stakeAddress, uint256 stakeAmount, uint256 stakeTime);
    event Unstaked(address stakeAddress, uint256 lockDays, uint256 stakeAmount,uint256 yieldAmount);
    //event OwnerDeposit();
    //event OwnerWithdraw();
    
    struct Stake {
        address stakeAddress;
        uint256 stakeAmount;
        uint256 stakeTime;
        //# duration: uint256
        uint256 yieldAmount;
        bool isAdded;
        bool staked;
    }
    
    address[] public staker_addresses;
    uint256 public stakeCount;
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
        uint256[] memory _rewardSteps,
        uint256[] memory _stakeSteps
    ){
        owner = msg.sender;
        //assert _stakeToken != ZERO_ADDRESS, "BoostPool: Vegatoken is zero address"
        stakeToken = _stakeToken;
        yieldToken = _yieldToken;
        duration = _duration;
        maxYield = _maxYield;
        maxStake = _maxStake;
        stakeDecimals = _stakeDecimals;
        yieldDecimals = _yieldDecimals;
        maxPerStake = _maxPerStake;        
        rewardSteps = _rewardSteps;        
        stakeSteps = _stakeSteps;  
        //self.stakingActive = True      
        //self.yieldTotal = 0
        startTime = block.timestamp;
        endTime = startTime + 30 * (1 days);

        totalAmountStaked = 0;
        currentStep = 0;
        rewardQuote = 1;
        //minPerStake = 1

    }    

    function setCurrentReward() public {
        //loop through stakesteps
        if (totalAmountStaked > stakeSteps[currentStep+1]){
            currentStep++;
        }
    }

    function stake(uint256 _stakeAmount) public {

        // assert self.stakingActive, "BoostPool: staking not active"    
        // assert block.timestamp < self.endTime, "BoostPool: ended"
        // assert block.timestamp >= self.startTime, "BoostPool: not started"
        // assert _stakeAmount <= self.maxPerStake, "BoostPool: more than maximum stake"
        // assert _stakeAmount >= self.minPerStake, "BoostPool: not enough"
        // assert self.totalAmountStaked + _stakeAmount <= self.maxStake,  "BoostPool: maximum staked"
        //assert not self.stakes[msg.sender].isAdded, "BoostPool: can only stake once"

        //uint256 bal = ERC20(stakeToken).balanceOf(msg.sender);

        //unclaimed: uint256 = bal - self.totalAmountStaked
        // assert unclaimed >= _stakeAmount, "BoostPool: need the tokens to stake"
        // # assert _duration >= 30, "BoostPool: need to stake at least 30 days"
        // # assert amount >= self.minstake

        // # assert self.rewardQuote > 0, "BoostPool: reward quote can not be 0"
        // #TODO
        // #reward based on total amount staked

        uint256 _yieldAmount = _stakeAmount * currentReward/rewardQuote;

        //assert self.yieldTotal + _yieldAmount <= self.maxYield, "BoostPool: rewards exhausted"
        staker_addresses[stakeCount] = msg.sender;
        stakeCount +=1;

        stakes[msg.sender] = Stake(
        {
            stakeAddress: msg.sender,
            stakeAmount: _stakeAmount,
            stakeTime: block.timestamp,
            //# duration: _duration,
            yieldAmount: _yieldAmount,
            isAdded: true,
            staked: true
        });    

        totalAmountStaked += _stakeAmount;

        setCurrentReward();

        //log StakeAdded(msg.sender, _stakeAmount, block.timestamp)

        //# transfer tokens
        bool transferSuccess = ERC20(stakeToken).transferFrom(msg.sender, address(this), _stakeAmount);
        require(transferSuccess, "BoostPool: transfer failed");

    }

    function unstake() public {

        //b: uint256 = ERC20(self.StakeToken).balanceOf(msg.sender)
        //assert self.stakes[msg.sender].isAdded, "BoostPool: not a stakeholder"
        //assert self.stakes[msg.sender].staked, "BoostPool: unstaked already"

        uint256 lockduration = block.timestamp - stakes[msg.sender].stakeTime;
        uint256 lockdays = lockduration/1 days;

        require(lockdays >= duration, "BoostPool: not locked for duration");

        //self.stakes[msg.sender].duration, "BoostPool: not locked according to duration"

        //transfer stake
        bool transferStakeSuccess = ERC20(stakeToken).transfer(msg.sender, stakes[msg.sender].stakeAmount);
        require(transferStakeSuccess, "BoostPool: sending stake failed");
        //transfer yield
        bool transferYieldSuccess = ERC20(yieldToken).transfer(msg.sender, stakes[msg.sender].yieldAmount);
        require(transferYieldSuccess, "BoostPool: sending yield failed");
        //assert ERC20(self.).transfer(msg.sender, self.stakes[msg.sender].), "BoostPool: sending yield failed"

        stakes[msg.sender].staked = false;

        totalAmountStaked -= stakes[msg.sender].stakeAmount;
        //log Unstake(msg.sender, lockdays, self.stakes[msg.sender].stakeAmount, self.stakes[msg.sender].yieldAmount)

    }

    //only Admin
    function depositOwner(uint256 amount) public {
        require(msg.sender == owner, "not the owner");

        //     assert (
        //     ERC20(self.YieldToken).allowance(msg.sender, self) >= amount
        // ), "BoostPool: not enough allowance"

        //     assert (
        //     ERC20(self.YieldToken).balanceOf(msg.sender) >= amount
        // ), "BoostPool: not enough balance"

        bool transferYieldSuccess = ERC20(yieldToken).transferFrom(msg.sender, address(this), amount);
        require(transferYieldSuccess, "BoostPool: sending yield failed");
        //log Deposit(amount)

    }

    function withdrawOwner(uint256 amount) public {
        require(msg.sender == owner, "not the owner");
        // bucketbalance: uint256 = ERC20(self.YieldToken).balanceOf(self)
        // unclaimedbalance: uint256 = bucketbalance - self.totalAmountStaked
        // assert amount <= unclaimedbalance, "BoostPool: can't withdraw staked amounts"

        bool transferYieldSuccess = ERC20(yieldToken).transfer(msg.sender, amount);
        require(transferYieldSuccess, "BoostPool: withdrawOwner");

        // # log WithdrawOwner(msg.sender, amount)

    }

}