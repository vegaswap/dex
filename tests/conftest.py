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
def boostpool(token, accounts):
    return BoostPool.deploy(token.address, token.address, 30, 10000, {"from": accounts[0]})

