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
    pool = BoostPool.deploy(
        token.address,
        token2.address,
        30,
        maxy,
        1000 * 10 ** 18,
        18,
        18,
        {"from": accounts[0]},
    )
    token2.transfer(pool, 10000 * 10 ** 18, {"from": accounts[0]})
    return pool
