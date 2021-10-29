#!/usr/bin/python3
import brownie
from brownie import chain


def test_basic(accounts, token, token2, boostpool):
    stakea = 1000 * 10**18
    token.approve(boostpool, stakea, {"from": accounts[0]})
    maxs = 10 ** 9 * 10 ** 18 - 5000 * 10**18
    assert token.balanceOf(accounts[0]) == maxs

    assert token.balanceOf(accounts[0]) == maxs
    boostpool.stake(stakea,  {"from": accounts[0]})

    assert boostpool.totalAmountStaked() == stakea
    assert token.balanceOf(boostpool) == stakea
    assert token.balanceOf(accounts[0]) == maxs - stakea

    s = boostpool.stakes(accounts[0])
    assert s[0] == accounts[0]
    assert s[1] == 1000 * 10**18
    assert s[2] > chain.time() - 10000
    assert s[3] == 5000 * 10**18
    # assert s[5] == True
    # assert s[6] == True

    with brownie.reverts("BoostPool: can only stake once"):
        token.approve(boostpool, 1000 * 10**18, {"from": accounts[0]})
        # boostpool.stake(1000, 30, {"from": accounts[0]})
        boostpool.stake(1000 * 10**18, {"from": accounts[0]})


# def test_unstake(accounts, token, token2, boostpool):
#     depositOwner = 2000
#     token2.approve(boostpool, depositOwner, {"from": accounts[0]})
#     boostpool.depositOwner(depositOwner, {"from": accounts[0]})
#     maxs = 10 ** 9 * 10 ** 18 - 5000
#     boostpool.activateStaking({"from": accounts[0]})

#     stakeAmount = 1000
#     stakeAccount = accounts[1]
#     token.approve(boostpool, stakeAmount, {"from": stakeAccount})
#     boostpool.stake(stakeAmount, {"from": stakeAccount})
#     assert boostpool.totalAmountStaked() == stakeAmount

#     chain.sleep(60 * 60 * 24 * 31)

#     assert token.balanceOf(accounts[0]) == maxs
#     # assert token2.balanceOf(accounts[0]) == maxs - depositOwner
    
#     # assert token2.balanceOf(stakeAccount) == maxs - stakeAmount - depositOwner

#     tx = boostpool.unstake({"from": stakeAccount})
#     # assert tx.events.keys() == ""
#     assert tx.events["Unstake"][0]["stakeAddress"] == stakeAccount
#     assert tx.events["Unstake"][0]["lockDays"] == 31
#     assert tx.events["Unstake"][0]["stakeAmount"] == 1000
#     assert tx.events["Unstake"][0]["yieldAmount"] == 5000
#     # maxs = 10 ** 9 * 10 ** 18
#     # assert token.balanceOf(accounts[0]) == maxs

#     assert boostpool.totalAmountStaked() == 0

#     # assert token.balanceOf(accounts[0]) == maxs - depositOwner

#     # assert token2.balanceOf(accounts[0]) == 5000


# def test_unstake2(accounts, token, token2, boostpool):
#     depositOwner = 2000
#     orig = token.balanceOf(accounts[1])
#     orig2 = token2.balanceOf(accounts[1])

#     token2.approve(boostpool, depositOwner, {"from": accounts[0]})
#     boostpool.depositOwner(depositOwner, {"from": accounts[0]})
#     maxs = 10 ** 9 * 10 ** 18
#     boostpool.activateStaking({"from": accounts[0]})

#     stakeAmount = 1000
#     token.approve(boostpool, stakeAmount, {"from": accounts[1]})
#     boostpool.stake(stakeAmount, {"from": accounts[1]})
#     assert boostpool.totalAmountStaked() == stakeAmount

#     chain.sleep(60 * 60 * 24 * 31)

#     assert token.balanceOf(accounts[1]) == orig - stakeAmount

#     rewardAmount = 5 * stakeAmount
#     before = token2.balanceOf(accounts[1])
#     tx = boostpool.unstake({"from": accounts[1]})
#     after = token2.balanceOf(accounts[1])
#     assert after - before == 5000
#     assert tx.events["Unstake"]["yieldAmount"] == 5000
#     # assert token.balanceOf(accounts[1]) == orig
#     assert token2.balanceOf(accounts[1]) == orig2 + rewardAmount

#     # assert boostpool.totalAmountStaked() == 0

#     # assert token.balanceOf(accounts[0]) == maxs  - depositOwner


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
