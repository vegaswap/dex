# @version ^0.2.15


from vyper.interfaces import ERC20

# original deployer
owner: address
StakeToken: public(address)
YieldToken: public(address)
days: constant(uint256) = 86400
stakeDecimals: public(uint256)
yieldDecimals: public(uint256)
#in days
duration: public(uint256)
startTime: public(uint256)
endTime: public(uint256)
#total number of yield promised
yieldTotal: public(uint256)
maxPerStake: public(uint256)
maxYield: public(uint256)
maxStake: public(uint256)
totalAmountStaked: public(uint256)
stakingActive: public(bool)
# reward: public(uint256)
currentStep: public(uint256)
currentReward: public(uint256)
rewardSteps: public(uint256[5])
stakeSteps: public(uint256[5])
rewardQuote: public(uint256)
minPerStake: public(uint256)

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
stakeCount: public(uint256)
stakes: public(HashMap[address, Stake])


@external
def __init__(
    _stakeToken: address,
    _yieldToken: address,
    _duration: uint256,
    _rewardSteps: uint256[5],
    _stakeSteps: uint256[5],
    _maxYield: uint256,
    _maxStake: uint256,
    _stakeDecimals: uint256,
    _yieldDecimals: uint256,
    _maxPerStake: uint256,
    # _name: String[15],
):
    assert _stakeToken != ZERO_ADDRESS, "BoostPool: Vegatoken is zero address"
    #TODO check
    # assert _duration in [30,60,90]

    self.owner = msg.sender    
    self.StakeToken = _stakeToken
    self.YieldToken = _yieldToken
    self.duration = _duration
    # self.reward = _reward
    self.rewardSteps = _rewardSteps
    self.stakeSteps = _stakeSteps
    self.rewardQuote = 1
    self.maxYield = _maxYield
    self.maxStake = _maxStake
    self.maxPerStake = _maxPerStake
    self.stakeDecimals = _stakeDecimals
    self.yieldDecimals = _yieldDecimals
    #activate by default
    self.stakingActive = True
    self.yieldTotal = 0
    self.startTime = block.timestamp
    self.endTime = self.startTime + (self.duration * days)
    #TODO
    # self.unstakeTime
    self.totalAmountStaked = 0
    self.currentStep = 0
    self.minPerStake = 1


@internal
def _currentReward():
    if self.totalAmountStaked > self.stakeSteps[4]:
        self.currentReward = self.rewardSteps[4]
    elif self.totalAmountStaked > self.stakeSteps[3]:
        self.currentReward = self.rewardSteps[3]
    elif self.totalAmountStaked > self.stakeSteps[2]:
        self.currentReward = self.rewardSteps[2]
    elif self.totalAmountStaked > self.stakeSteps[1]:
        self.currentReward = self.rewardSteps[1]
    else:
        self.currentReward = self.rewardSteps[0]

@external
def setreward():
    self._currentReward()

@external
def stake(_stakeAmount: uint256):
    assert self.stakingActive, "BoostPool: staking not active"    
    assert block.timestamp < self.endTime, "BoostPool: ended"
    assert block.timestamp >= self.startTime, "BoostPool: not started"
    assert _stakeAmount <= self.maxPerStake, "BoostPool: more than maximum stake"
    assert _stakeAmount >= self.minPerStake, "BoostPool: not enough"

    assert self.totalAmountStaked + _stakeAmount <= self.maxStake,  "BoostPool: maximum staked"

    bal: uint256 = ERC20(self.StakeToken).balanceOf(msg.sender)
    unclaimed: uint256 = bal - self.totalAmountStaked
    assert unclaimed >= _stakeAmount, "BoostPool: need the tokens to stake"
    # assert _duration >= 30, "BoostPool: need to stake at least 30 days"
    # assert amount >= self.minstake

    assert not self.stakes[msg.sender].isAdded, "BoostPool: can only stake once"
    
    # assert self.rewardQuote > 0, "BoostPool: reward quote can not be 0"
    #TODO
    #reward based on total amount staked
    self._currentReward()
    _yieldAmount: uint256 = _stakeAmount * self.currentReward/self.rewardQuote

    assert self.yieldTotal + _yieldAmount <= self.maxYield, "BoostPool: rewards exhausted"
    self.staker_addresses[self.stakeCount] = msg.sender
    self.stakeCount +=1
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
    # days: uint256 = 60*60*24
    lockdays: uint256 = lockduration/days
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
        ERC20(self.YieldToken).allowance(msg.sender, self) >= amount
    ), "BoostPool: not enough allowance"

    assert (
        ERC20(self.YieldToken).balanceOf(msg.sender) >= amount
    ), "BoostPool: not enough balance"
    transferSuccess: bool = ERC20(self.YieldToken).transferFrom(msg.sender, self, amount)
    assert transferSuccess, "BoostPool: deposit failed"
    log Deposit(amount)

@external
def withdrawOwner(amount: uint256):
    assert msg.sender == self.owner, "BoostPool: not the owner"

    bucketbalance: uint256 = ERC20(self.YieldToken).balanceOf(self)
    unclaimedbalance: uint256 = bucketbalance - self.totalAmountStaked
    assert amount <= unclaimedbalance, "BoostPool: can't withdraw staked amounts"
    transferSuccess: bool = ERC20(self.YieldToken).transfer(msg.sender, amount)
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