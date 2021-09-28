# #!/usr/bin/python3
import brownie
from brownie import chain


# def test_stakereward(accounts, token, boostpool):
#     boostpool.activateStaking( {"from": accounts[0]})
#     rewday = 1
#     # boostpool.setReward(rewday, {"from": accounts[0]})
#     # boostpool.setRewardQuote(250, {"from": accounts[0]})

#     token.approve(boostpool, 2000, {"from": accounts[0]})
#     boostpool.depositOwner(2000, {"from": accounts[0]})

#     token.transfer(accounts[1], 1000)

#     t = chain.time()
#     stakeAmount = 1000
#     token.approve(boostpool, stakeAmount, {"from": accounts[1]})
#     tx = boostpool.stake(1000, 30, {"from": accounts[1]})

#     assert tx.events["StakeAdded"][0]["stakeTime"] == t

#     s = boostpool.stakes(accounts[1])
#     assert s[0]== accounts[1]
#     assert s[1] == 1000
#     assert s[2] - t < 10
#     assert s[3] == 30
#     assert s[4] == True

#     lockdays = 30
#     chain.sleep(60*60*24*lockdays)
#     tx = boostpool.unstake({"from": accounts[1]})
