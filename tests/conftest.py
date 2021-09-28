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
    return VegaToken.deploy({"from": accounts[0]})


@pytest.fixture(scope="module")
def token2(VegaToken, accounts):
    return VegaToken.deploy({"from": accounts[0]})


@pytest.fixture(scope="module")
def boostpool(token, token2, accounts):
    maxy = 10000 * 10 ** 18
    dur = 30
    reward = 1
    maxs = 1000 * 10 ** 18
    pool = BoostPool.deploy(
        token.address,
        token2.address,
        dur,
        reward,
        maxy,
        # 1000 * 10 ** 18,
        18,
        18,
        maxs,
        {"from": accounts[0]},
    )
    token2.transfer(pool, 10000 * 10 ** 18, {"from": accounts[0]})
    return pool

@pytest.fixture(scope="module")
def boostpool2(token, token2, accounts):
    maxy = 10000 * 10 ** 18
    dur = 30
    reward = 5
    maxs = 1000 * 10 ** 18
    pool = BoostPool.deploy(
        token.address,
        token2.address,
        dur,
        reward,
        maxy,
        # 1000 * 10 ** 18,
        18,
        18,
        maxs,
        {"from": accounts[0]},
    )
    token2.transfer(pool, 10000 * 10 ** 18, {"from": accounts[0]})
    return pool
