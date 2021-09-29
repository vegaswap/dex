# @version ^0.2.15

# boost pool
# functions like airdrop

# TODO: token availability?
# TODO: dynamic formula
# TODO: define time window for staking
# TODO: dynamic price
# 
#     t0          t1     t2     t3
#     announce    start  final  unstake event

# todo: how to avoid sell after unstake event
# rolling time window?
# consider extra lock
# max stake is like logartihmic interest rate

from vyper.interfaces import ERC20

# original deployer
owner: address
StakeToken: public(address)
YieldToken: public(address)
days: constant(uint256) = 86400
stakeDecimals: uint256
yieldDecimals: uint256
#in days
duration: uint256
startTime: uint256
endTime: uint256
#total number of yield promised
yieldTotal: public(uint256)
maxPerStake: public(uint256)
maxYield: uint256
totalAmountStaked: public(uint256)
stakingActive: public(bool)
reward: public(uint256)
rewardQuote: public(uint256)

event Deposit:
    amount: uint256

event StakeAdded:
    stakeAddress: address
    stakeAmount: uint256
    stakeTime: uint256

event Unstake:
    stakeAddress: address
    lockDays: uint256
    stakeAmount: uint256
    yieldAmount: uint256

# duration in days
struct Stake:
    stakeAddress: address
    stakeAmount: uint256
    stakeTime: uint256
    # duration: uint256
    yieldAmount: uint256
    isAdded: bool
    staked: bool


# TOOD consider max array
staker_addresses: public(address[10000])
stakeCount: uint256
stakes: public(HashMap[address, Stake])


@external
def __init__(
    _stakeToken: address,
    _yieldToken: address,
    _duration: uint256,
    _reward: uint256,   
    _maxYield: uint256,
    _stakeDecimals: uint256,
    _yieldDecimals: uint256,
    _maxPerStake: uint256,
    # _name: String[15],
):
    assert _stakeToken != ZERO_ADDRESS, "BoostPool: Vegatoken is zero address"
    #TODO check
    assert _duration in [30,60,90]

    self.owner = msg.sender    
    self.StakeToken = _stakeToken
    self.YieldToken = _yieldToken
    self.duration = _duration
    self.reward = _reward
    self.rewardQuote = 1
    self.maxYield = _maxYield
    self.maxPerStake = _maxPerStake
    self.stakeDecimals = _stakeDecimals
    self.yieldDecimals = _yieldDecimals
    self.stakingActive = False
    self.yieldTotal = 0
    # self.reward = 0
    #TODO start
    self.startTime = block.timestamp
    self.endTime = self.startTime + (self.duration * days)


@external
def stake(_stakeAmount: uint256):
    assert self.stakingActive, "BoostPool: staking not active"    
    assert block.timestamp < self.endTime, "BoostPool: ended"
    assert block.timestamp >= self.startTime, "BoostPool: not started"
    assert _stakeAmount <= self.maxPerStake, "BoostPool: more than maximum stake"

    bal: uint256 = ERC20(self.StakeToken).balanceOf(msg.sender)
    unclaimed: uint256 = bal - self.totalAmountStaked
    assert unclaimed >= _stakeAmount, "BoostPool: need the tokens to stake"
    # assert _duration >= 30, "BoostPool: need to stake at least 30 days"
    # assert amount >= self.minstake

    assert not self.stakes[msg.sender].isAdded, "BoostPool: can only stake once"
    
    # assert self.rewardQuote > 0, "BoostPool: reward quote can not be 0"
    _yieldAmount: uint256 = _stakeAmount * self.reward/self.rewardQuote

    assert self.yieldTotal + _yieldAmount <= self.maxYield, "BoostPool: rewards exhausted"
    self.staker_addresses[self.stakeCount] = msg.sender
    self.stakes[msg.sender] = Stake(
        {
            stakeAddress: msg.sender,
            stakeAmount: _stakeAmount,
            stakeTime: block.timestamp,
            # duration: _duration,
            yieldAmount: _yieldAmount,
            isAdded: True,
            staked: True
        }
    )
    self.totalAmountStaked += _stakeAmount
    log StakeAdded(msg.sender, _stakeAmount, block.timestamp)

    # transfer tokens
    transferSuccess: bool = ERC20(self.StakeToken).transferFrom(msg.sender, self, _stakeAmount)
    assert transferSuccess, "BoostPool: transfer failed"


@external
def unstake():
    b: uint256 = ERC20(self.StakeToken).balanceOf(msg.sender)
    assert self.stakes[msg.sender].isAdded, "BoostPool: not a stakeholder"
    assert self.stakes[msg.sender].staked, "BoostPool: unstaked already"

    lockduration: uint256 = block.timestamp - self.stakes[msg.sender].stakeTime
    lockdays: uint256 = lockduration/(60*60*24)    
    assert lockdays >= self.duration, "BoostPool: not locked for duration"    
    # self.stakes[msg.sender].duration, "BoostPool: not locked according to duration"

    # transfer stake
    assert ERC20(self.StakeToken).transfer(msg.sender, self.stakes[msg.sender].stakeAmount), "BoostPool: sending stake failed"
    # transfer yield
    assert ERC20(self.YieldToken).transfer(msg.sender, self.stakes[msg.sender].yieldAmount), "BoostPool: sending yield failed"

    self.stakes[msg.sender].staked = False

    self.totalAmountStaked -= self.stakes[msg.sender].stakeAmount

    log Unstake(msg.sender, lockdays, self.stakes[msg.sender].stakeAmount, self.stakes[msg.sender].yieldAmount)

# @external
# def setReward(_rewardPerDay: uint256):
#     assert msg.sender == self.owner, "BoostPool: not the owner"
#     self.rewardPerDay = _rewardPerDay
    
# @external
# def setRewardQuote(_rewardQuote: uint256):
#     assert msg.sender == self.owner, "BoostPool: not the owner"
#     self.rewardQuote = _rewardQuote
        
@external
def depositOwner(amount: uint256):
    assert msg.sender == self.owner, "BoostPool: not the owner"
    assert (
        ERC20(self.StakeToken).allowance(msg.sender, self) >= amount
    ), "BoostPool: not enough allowance"

    assert (
        ERC20(self.StakeToken).balanceOf(msg.sender) >= amount
    ), "BoostPool: not enough balance"
    transferSuccess: bool = ERC20(self.StakeToken).transferFrom(msg.sender, self, amount)
    assert transferSuccess, "BoostPool: deposit failed"
    log Deposit(amount)

@external
def withdrawOwner(amount: uint256):
    assert msg.sender == self.owner, "BoostPool: not the owner"

    bucketbalance: uint256 = ERC20(self.StakeToken).balanceOf(self)
    unclaimedbalance: uint256 = bucketbalance - self.totalAmountStaked
    assert amount <= unclaimedbalance, "BoostPool: can't withdraw staked amounts"
    transferSuccess: bool = ERC20(self.StakeToken).transfer(msg.sender, amount)
    assert transferSuccess, "BoostPool: withdraw failed"
    # log WithdrawOwner(msg.sender, amount)

@external
def activateStaking():
    assert msg.sender == self.owner, "BoostPool: not the owner"
    self.stakingActive = True

@external
def deactivateStaking():
    assert msg.sender == self.owner, "BoostPool: not the owner"
    self.stakingActive = False