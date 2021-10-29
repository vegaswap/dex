// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BoostPool {

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
    // rewardSteps: public(uint256[5])
    // stakeSteps: public(uint256[5])
    // uint256 rewardQuote
    // uint256 minPerStake

    constructor(
        address _stakeToken,
        address _yieldToken,
        uint256 _duration,
        uint256 _maxYield,
        uint256 _maxStake,
        uint256 _stakeDecimals,
        uint256 _yieldDecimals,
        uint256 _maxPerStake
    ){
        stakeToken = _stakeToken;
        yieldToken = _yieldToken;
        duration = _duration;
        maxYield = _maxYield;
        maxStake = _maxStake;
        stakeDecimals = _stakeDecimals;
        yieldDecimals = _yieldDecimals;
        maxPerStake = _maxPerStake;        


    }




}