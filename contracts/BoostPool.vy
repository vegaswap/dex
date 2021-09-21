# @version ^0.2.15

# boost pool
# parameters
# _duration: uint256
# total amount to stake


# TODO: token availability problem
# TODO: consider the case when not enough staking rewards are left?


from vyper.interfaces import ERC20

# original deployer
owner: address
StakeToken: address
YieldToken: address
days: constant(uint256) = 86400
decimals: uint256
duration: uint256
startTime: uint256
endTime: uint256
maxStake: uint256
totalAmountStaked: public(uint256)
stakingActive: public(bool)
rewardPerDay: public(uint256)
rewardQuote: public(uint256)

event Deposit:
    amount: uint256

event StakeAdded:
    stakeAddress: address
    stakeAmount: uint256
    stakeTime: uint256

event Unstake:
    stakeAddress: address
    duration: uint256
    interest: uint256
    amount: uint256

# duration in days
struct Stake:
    stakeAddress: address
    stakeAmount: uint256
    stakeTime: uint256
    duration: uint256
    isAdded: bool


# TOOD consider max array
staker_addresses: public(address[10000])
stakeCount: uint256
stakes: public(HashMap[address, Stake])


@external
def __init__(
    _stakeToken: address,
    _yieldToken: address,
    _duration: uint256,
    _maxStake: uint256
    # _name: String[15],
):
    assert _stakeToken != ZERO_ADDRESS, "BoostPool: Vegatoken is zero address"
    assert _duration in [30,60,90]

    self.StakeToken = _stakeToken
    self.YieldToken = _yieldToken
    self.owner = msg.sender    
    decimals: uint256 = 18
    self.stakingActive = False
    self.rewardPerDay = 0
    self.rewardQuote = 1
    self.duration = _duration
    self.startTime = block.timestamp
    self.endTime = self.startTime + self.duration


@external
def stake(_stakeAmount: uint256, _duration: uint256):
    #TODO need to check again pool, need always a reserve to pay out    
    assert self.stakingActive, "BoostPool: staking not active"
    assert block.timestamp < self.endTime, "BoostPool: ended"
    assert block.timestamp >= self.startTime, "BoostPool: not started"

    bal: uint256 = ERC20(self.StakeToken).balanceOf(msg.sender)
    unclaimed: uint256 = bal - self.totalAmountStaked
    assert unclaimed >= _stakeAmount, "BoostPool: need the tokens to stake"
    assert _duration >= 30, "BoostPool: need to stake at least 30 days"
    # assert amount >= self.minstake

    assert not self.stakes[msg.sender].isAdded, "BoostPool: can only stake once"

    self.staker_addresses[self.stakeCount] = msg.sender
    self.stakes[msg.sender] = Stake(
        {
            stakeAddress: msg.sender,
            stakeAmount: _stakeAmount,
            stakeTime: block.timestamp,
            duration: _duration,
            isAdded: True,
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

    lockduration: uint256 = block.timestamp - self.stakes[msg.sender].stakeTime
    lockdays: uint256 = lockduration/(60*60*24)
    assert lockdays >= 30, "BoostPool: not staked long enough. 30 days required"
    assert self.rewardQuote > 0, "BoostPool: reward quote can not be 0"
    interest: uint256 = lockdays * self.rewardPerDay * self.stakes[msg.sender].stakeAmount/self.rewardQuote

    # transfer total and then interest
    totalAmount: uint256 = self.stakes[msg.sender].stakeAmount + interest
    assert ERC20(self.StakeToken).balanceOf(self) >= totalAmount, "BoostPool: not enough tokens"
    # transferSuccess: bool = ERC20(self.StakeToken).transfer(msg.sender, totalAmount)
    transferSuccess: bool = ERC20(self.StakeToken).transfer(msg.sender, totalAmount)
    assert transferSuccess, "BoostPool: unstake failed"

    log Unstake(msg.sender, lockdays, interest, totalAmount)

    self.stakes[msg.sender].stakeAmount = 0

@external
def calcReward():
    #calc APY
    pass

@external
def setReward(_rewardPerDay: uint256):
    assert msg.sender == self.owner, "BoostPool: not the owner"
    self.rewardPerDay = _rewardPerDay
    
@external
def setRewardQuote(_rewardQuote: uint256):
    assert msg.sender == self.owner, "BoostPool: not the owner"
    self.rewardQuote = _rewardQuote
        
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