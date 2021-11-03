# #!/usr/bin/python3
import brownie
from brownie import chain
from brownie import chain, VegaToken, BoostPool

def test_model(accounts, token, token2):
    
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
        {"from": accounts[0]},
    )
    token2.transfer(pool, 10000 * 10 ** 18, {"from": accounts[0]})


    stakeaccount = accounts[1]
    ma = accounts[0]
    token.transfer(stakeaccount, 10000 * 10 ** 18, {"from": ma})

    stakea = 100 * 10**18
    token.approve(pool, stakea, {"from": stakeaccount})

    maxs = 10 ** 9 * 10 ** 18 - 5000 * 10**18
    assert token.balanceOf(accounts[0]) == maxs

    c = pool.currentStep()
    assert c == 0
    r = pool.rewardSteps(c)

    assert token.balanceOf(accounts[0]) == maxs
    pool.stake(stakea,  {"from": accounts[0]})

    #token2.transfer(pool, 10000 * 10 ** 18, {"from": accounts[0]})