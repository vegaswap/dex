#!/usr/bin/python3

import pytest
from brownie import chain, VegaToken, BoostPool


@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.10.3/tests-pytest-intro.html#isolation-fixtures
    pass


@pytest.fixture(scope="module")
def token(VegaToken, accounts):
    token = VegaToken.deploy({"from": accounts[0]})
    token.transfer(accounts[1], 5000 * 10**18, {"from": accounts[0]})
    return token


@pytest.fixture(scope="module")
def token2(VegaToken, accounts):
    token = VegaToken.deploy({"from": accounts[0]})
    token.transfer(accounts[1], 5000 * 10**18, {"from": accounts[0]})
    return token


@pytest.fixture(scope="module")
def boostpool(token, token2, accounts):
    maxy = 10000 * 10 ** 18
    maxStake = 100000 * 10 ** 18    
    days = 60*60*24
    dur = 30 * days
    reward = [5, 2, 0, 0, 0]
    ssteps = [0, 1000, 1000, 1000, 1000]
    maxs = 1000 * 10 ** 18
    # mins = 100 * 10 ** 18
    _rewardQuote = 1
    pool = BoostPool.deploy(
        token.address,
        token2.address,
        dur,        
        maxy,
        maxStake,        
        18,
        18,
        maxs,
        # mins,
        reward,
        ssteps,
        _rewardQuote,
        {"from": accounts[0]},
    )
    token2.transfer(pool, 10000 * 10 ** 18, {"from": accounts[0]})
    return pool


@pytest.fixture(scope="module")
def boostpool2(token, token2, accounts):
    maxy = 10000 * 10 ** 18
    maxStake = 100000 * 10 ** 18
    days = 60*60*24
    dur = 30 * days
    reward = [10, 8, 4, 2, 1]
    ssteps = [0, 1000, 2000, 3000, 4000]
    maxs = 1000 * 10 ** 18
    pool = BoostPool.deploy(
        token.address,
        token2.address,
        dur,
        reward,
        ssteps,
        maxy,
        maxStake,
        # 1000 * 10 ** 18,
        18,
        18,
        maxs,
        {"from": accounts[0]},
    )
    token2.transfer(pool, 10000 * 10 ** 18, {"from": accounts[0]})
    return pool
