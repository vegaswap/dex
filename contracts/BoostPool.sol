// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

//--- Boost Pool ---
// a pool for fixed duration staking rewards
// the number of reward is fixed at deploy
// stakers can stake until start + duration is reached
// they can unstake after that
// the APY will go up if one stakes as the time decreases

import "./erc20.sol";

contract BoostPool {
    address public owner;

    address public stakeToken;
    address public yieldToken;
    // start when stake is possible
    uint256 public startTime;
    // end after which unstake becomes possible
    uint256 public endTime;
    uint256 public stakeDecimals;
    uint256 public yieldDecimals;
    uint256 public maxPerStake;
    uint256 public maxYield;
    uint256 public maxStake;
    uint256 public totalAmountStaked;
    uint256 public totalAmountClaimed;
    uint256 public currentStep;

    uint256[] public rewardSteps;
    uint256[] public stakeSteps;
    uint256 public rewardQuote;
    uint256 public minPerStake;

    event Deposit(uint256 amount);
    event StakeAdded(address stakeAddress, uint256 stakeAmount, uint256 yieldAmount, uint256 stakeTime);
    event Unstaked(address stakeAddress, uint256 stakeAmount, uint256 yieldAmount);
    event OwnerDeposit(uint256 amount);
    event OwnerWithdraw(uint256 amount);

    struct Stake {
        address stakeAddress;
        uint256 stakeAmount;
        uint256 yieldAmount;
        bool isAdded;
        bool staked;
        uint256 stakeTime;
    }

    address[] public staker_addresses;
    mapping(address => Stake) public stakes;

    constructor(
        uint256 _startTime,
        uint256 _duration,
        address _stakeToken,
        address _yieldToken,
        uint256 _maxYield,
        uint256 _maxStake,
        uint256 _maxPerStake,
        uint256[] memory _rewardSteps,
        uint256[] memory _stakeSteps,
        uint256 _rewardQuote
    ) {
        owner = msg.sender;
        stakeToken = _stakeToken;
        yieldToken = _yieldToken;
        maxYield = _maxYield;
        maxStake = _maxStake;
        //assume 18
        stakeDecimals = 18;
        yieldDecimals = 18;
        maxPerStake = _maxPerStake;
        rewardSteps = _rewardSteps;
        stakeSteps = _stakeSteps;

        startTime = _startTime;
        endTime = startTime + _duration;
        rewardQuote = _rewardQuote;

        totalAmountStaked = 0;
        totalAmountClaimed = 0;
        currentStep = 0;
        minPerStake = 1 * 10**stakeDecimals;
    }

    function stake(uint256 _stakeAmount) public {
        require(block.timestamp < endTime, "BoostPool: ended");
        require(block.timestamp >= startTime, "BoostPool: not started");
        require(_stakeAmount <= maxPerStake, "BoostPool: more than maximum stake");
        require(_stakeAmount >= minPerStake, "BoostPool: not enough");
        require(totalAmountStaked + _stakeAmount <= maxStake, "BoostPool: maximum staked");
        require(!stakes[msg.sender].isAdded, "BoostPool: can only stake once");

        uint256 _yieldAmount = (_stakeAmount * rewardSteps[currentStep]) / rewardQuote;

        //TODO
        //require(totalAmountClaimed + _yieldAmount <= maxYield, "BoostPool: rewards exhausted");
        //check available yield tokens
        //uint256 bal = ERC20(yieldToken).balanceOf(address(this));
        //uint256 unclaimed = bal - totalAmountClaimed;
        //require(unclaimed >= _yieldAmount, "BoostPool: need the tokens to stake");

        require(ERC20(stakeToken).transferFrom(msg.sender, address(this), _stakeAmount), "BoostPool: transfer failed");
        staker_addresses.push(msg.sender);

        stakes[msg.sender] = Stake({
        stakeAddress: msg.sender,
        stakeAmount: _stakeAmount,
        yieldAmount: _yieldAmount,
        isAdded: true,
        staked: true,
        stakeTime: block.timestamp
        });

        totalAmountStaked += _stakeAmount;
        totalAmountClaimed += _yieldAmount;

        require(currentStep < stakeSteps.length, "max stake reached");

        if (totalAmountStaked >= stakeSteps[currentStep]) {
            currentStep++;
        }

        emit StakeAdded(msg.sender, _stakeAmount, _yieldAmount, block.timestamp);
    }

    function unstake() public {
        require(stakes[msg.sender].isAdded, "BoostPool: not a stakeholder");
        require(stakes[msg.sender].staked, "BoostPool: not staked");

        require(block.timestamp >= endTime, "BoostPool: not locked for duration");

        //transfer stake
        require(ERC20(stakeToken).transfer(msg.sender, stakes[msg.sender].stakeAmount), "BoostPool: sending stake failed");
        //transfer yield
        require(ERC20(yieldToken).transfer(msg.sender, stakes[msg.sender].yieldAmount), "BoostPool: sending yield failed");

        stakes[msg.sender].staked = false;
    
        emit Unstaked(msg.sender, stakes[msg.sender].stakeAmount, stakes[msg.sender].yieldAmount);
    }

    function depositOwner(uint256 amount) public {
        require(msg.sender == owner, "not the owner");

        require(ERC20(yieldToken).allowance(msg.sender, address(this)) >= amount, "BoostPool: not enough allowance");
        require(ERC20(yieldToken).balanceOf(msg.sender) >= amount, "BoostPool: not enough balance");

        require(ERC20(yieldToken).transferFrom(msg.sender, address(this), amount), "BoostPool: sending yield failed");

        emit OwnerDeposit(amount);
    }

    function withdrawOwnerYield(uint256 amount) public {
        require(msg.sender == owner, "not the owner");
        //TODO
        //uint256 bucketbalance = ERC20(yieldToken).balanceOf(address(this));
        //uint256 unclaimedbalance = bucketbalance - totalAmountClaimed;
        //require(amount <= unclaimedbalance, "BoostPool: can't withdraw staked amounts");

        require(ERC20(yieldToken).transfer(msg.sender, amount), "BoostPool: withdrawOwner yield");

        emit OwnerWithdraw(amount);
    }

    //emergency withdraw of the stake.
    //TODO remove
    function withdrawOwnerStake(uint256 amount) public {
        require(msg.sender == owner, "not the owner");

        //uint256 bucketbalance = ERC20(yieldToken).balanceOf(address(this));
        //uint256 unclaimedbalance = bucketbalance - totalAmountClaimed;
        //require(amount <= unclaimedbalance, "BoostPool: can't withdraw staked amounts");

        require(ERC20(stakeToken).transfer(msg.sender, amount), "BoostPool: withdrawOwner stake");

        emit OwnerWithdraw(amount);
    }
}
