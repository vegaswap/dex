#!/usr/bin/python3
import brownie
from brownie import chain


def test_basic(accounts, token, boostpool):
    token.approve(boostpool, 1000, {"from": accounts[0]})
    maxs = 10 ** 9 * 10 ** 18
    assert token.balanceOf(accounts[0]) == maxs

    boostpool.activateStaking({"from": accounts[0]})
    boostpool.stake(1000, {"from": accounts[0]})

    assert token.balanceOf(boostpool) == 1000
    assert token.balanceOf(accounts[0]) == maxs - 1000

    s = boostpool.stakes(accounts[0])
    assert s[0] == accounts[0]
    assert s[1] == 1000
    assert s[2] > chain.time() - 10000
    assert s[3] == 0
    # assert s[5] == True
    # assert s[6] == True

    with brownie.reverts("BoostPool: can only stake once"):
        token.approve(boostpool, 1000, {"from": accounts[0]})
        # boostpool.stake(1000, 30, {"from": accounts[0]})
        boostpool.stake(1000, {"from": accounts[0]})


def test_unstake(accounts, token, boostpool):
    token.approve(boostpool, 2000, {"from": accounts[0]})
    boostpool.depositOwner(2000, {"from": accounts[0]})
    maxs = 10 ** 9 * 10 ** 18
    boostpool.activateStaking({"from": accounts[0]})

    token.approve(boostpool, 1000, {"from": accounts[0]})
    boostpool.stake(1000, {"from": accounts[0]})

    chain.sleep(60 * 60 * 24 * 31)

    boostpool.unstake({"from": accounts[0]})
    maxs = 10 ** 9 * 10 ** 18
    # assert token.balanceOf(accounts[0]) == maxs - 2000


# def test_stakereward(accounts, token, boostpool):
#     boostpool.activateStaking({"from": accounts[0]})
#     rewday = 1
#     boostpool.setReward(rewday, {"from": accounts[0]})
#     boostpool.setRewardQuote(1, {"from": accounts[0]})

#     assert boostpool.rewardPerDay() == 1
#     assert boostpool.rewardQuote() == 1

#     token.approve(boostpool, 2000, {"from": accounts[0]})
#     boostpool.depositOwner(2000, {"from": accounts[0]})

#     token.transfer(accounts[1], 1000)

#     t = chain.time()
#     stakeAmount = 1000
#     token.approve(boostpool, stakeAmount, {"from": accounts[1]})
#     tx = boostpool.stake(1000, {"from": accounts[1]})

#     # with brownie.reverts("Staking: not a stakeholder"):
#     with brownie.reverts():
#         tx = boostpool.stake(1000, {"from": accounts[2]})

#     assert tx.events["StakeAdded"][0]["stakeTime"] == t

#     s = boostpool.stakes(accounts[1])
#     assert s[0] == accounts[1]
#     assert s[1] == stakeAmount
#     assert s[2] - t < 10
#     assert s[3] == 30
#     # yield
#     assert s[4] == 30 * stakeAmount

#     lockdays = 30
#     chain.sleep(60 * 60 * 24 * lockdays)
#     tx = boostpool.unstake({"from": accounts[1]})
#     assert tx.events["Unstake"][0]["duration"] == 30
#     assert tx.events["Unstake"][0]["stakeAmount"] == stakeAmount
#     assert tx.events["Unstake"][0]["yieldAmount"] == 30 * stakeAmount

#     # assert tx.events["Unstake"][0]["amount"] == 1120


# def test_stakerewardQuote(accounts, token, boostpool):
#     boostpool.activateStaking({"from": accounts[0]})
#     rewday = 1
#     boostpool.setReward(rewday, {"from": accounts[0]})
#     boostpool.setRewardQuote(100, {"from": accounts[0]})

#     assert boostpool.rewardPerDay() == 1
#     assert boostpool.rewardQuote() == 100

#     token.approve(boostpool, 2000, {"from": accounts[0]})
#     boostpool.depositOwner(2000, {"from": accounts[0]})

#     token.transfer(accounts[1], 1000)

#     t = chain.time()
#     stakeAmount = 1000
#     token.approve(boostpool, stakeAmount, {"from": accounts[1]})
#     tx = boostpool.stake(1000, {"from": accounts[1]})

#     # with brownie.reverts("Staking: not a stakeholder"):
#     with brownie.reverts():
#         tx = boostpool.stake(1000, {"from": accounts[2]})

#     assert tx.events["StakeAdded"][0]["stakeTime"] == t

#     s = boostpool.stakes(accounts[1])
#     assert s[0] == accounts[1]
#     assert s[1] == stakeAmount
#     assert s[2] - t < 10
#     assert s[3] == 30
#     # yield
#     assert s[4] == 30 * stakeAmount / 100

#     lockdays = 30
#     chain.sleep(60 * 60 * 24 * lockdays)
#     tx = boostpool.unstake({"from": accounts[1]})
#     assert tx.events["Unstake"][0]["duration"] == 30
#     assert tx.events["Unstake"][0]["stakeAmount"] == stakeAmount
#     assert tx.events["Unstake"][0]["yieldAmount"] == 30 * stakeAmount / 100

#     # assert tx.events["Unstake"][0]["amount"] == 1120
