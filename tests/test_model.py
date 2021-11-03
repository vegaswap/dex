# #!/usr/bin/python3
import brownie
from brownie import chain
from brownie import chain, VegaToken, BoostPool

def test_model(accounts, token, token2):

    mainaccount = accounts[0]
    stakeaccount = accounts[1]
    
    hour = 60*60
    day = 24 * hour
    _duration = hour * 6
    f = 10 ** 18
    _maxYield = 4000 * f
    _maxTotalStake = 500 * f
    _stakeDecimals = 18
    _yieldDecimals = 18
    _maxPerStake = 1000 * f
    _minStake = 10 * f
    _rewardSteps = [15, 11, 8, 6, 4]        
    _stakeSteps = [100 * f, 200 * f, 300 * f, 400 * f] 
    rewardQuote = 1
    pool = BoostPool.deploy(
        token,
        token2,
        _duration,
        _maxYield,
        _maxTotalStake,
        _stakeDecimals,
        _yieldDecimals,
        _maxPerStake,
        # _minStake,
        _rewardSteps,
        _stakeSteps,
        rewardQuote,
        {"from": mainaccount},
    )

    total = 10 ** 9 * 10 ** 18

    depAmount = 20000 * 10 ** 18
    token2.transfer(pool, depAmount, {"from": mainaccount})

    
    transfera = 10000 * 10 ** 18
    token.transfer(stakeaccount, transfera, {"from": mainaccount})

    stakea = 100 * 10**18
    token.approve(pool, stakea, {"from": stakeaccount})
    

    assert pool.totalAmountClaimed() == 0
    c = pool.currentStep()
    assert c == 0
    r = pool.rewardSteps(c)

    #assert token.balanceOf(accounts[0]) == total
    pool.stake(stakea,  {"from": stakeaccount})

    assert pool.totalAmountClaimed() == stakea * r
    
    assert token.balanceOf(mainaccount) == total - transfera
    assert token.balanceOf(stakeaccount) == transfera - stakea
    assert token.balanceOf(pool) == stakea


    token.transfer(accounts[2], stakea, {"from": mainaccount})
    

    token.approve(pool, stakea, {"from": accounts[2]})
    pool.stake(stakea,  {"from": accounts[2]})
    
    assert token.balanceOf(pool) == stakea*2
    assert pool.totalAmountStaked() == stakea*2

    s = pool.stakes(accounts[2])
    assert s[0] == accounts[2]
    assert s[1] == stakea
    assert s[2] == stakea * 11
    assert s[3] == True
    assert s[4] == True

    assert pool.totalAmountClaimed() == (stakea * 15) + (stakea * 11)

    c = pool.currentStep()
    assert c == 2

    i = 3
    token.transfer(accounts[i], stakea, {"from": mainaccount})
    token.approve(pool, stakea, {"from": accounts[i]})
    pool.stake(stakea,  {"from": accounts[i]})
    c = pool.currentStep()
    assert c == 3
    assert pool.totalAmountStaked() == stakea*3

    i = 4
    token.transfer(accounts[i], stakea, {"from": mainaccount})
    token.approve(pool, stakea, {"from": accounts[i]})
    pool.stake(stakea,  {"from": accounts[i]})
    c = pool.currentStep()
    assert c == 4
    assert pool.totalAmountStaked() == stakea*4

    i = 5
    with brownie.reverts():
        token.transfer(accounts[i], stakea, {"from": mainaccount})
        token.approve(pool, stakea, {"from": accounts[i]})
        pool.stake(stakea,  {"from": accounts[i]})
        c = pool.currentStep()
        assert c == 5

    #assert token.balanceOf(stakeaccount) == transfera - stakea

    #token2.transfer(pool, 10000 * 10 ** 18, {"from": accounts[0]})


    #test reward quote