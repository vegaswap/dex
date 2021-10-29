# #!/usr/bin/python3
# import brownie
# from brownie import chain


# def test_unstake(accounts, token, token2, boostpool2):
#     depositOwner = 2000
#     token2.approve(boostpool2, depositOwner, {"from": accounts[0]})
#     boostpool2.depositOwner(depositOwner, {"from": accounts[0]})
#     maxs = 10 ** 9 * 10 ** 18 - 5000
#     boostpool2.setreward()
#     assert boostpool2.currentReward() == 10

#     # boostpool2.activateStaking({"from": accounts[0]})
#     # stakeAmount = 1000
#     # token.approve(boostpool2, stakeAmount, {"from": accounts[0]})
#     # boostpool2.stake(stakeAmount, {"from": accounts[0]})
#     # assert boostpool2.totalAmountStaked() == stakeAmount

#     # chain.sleep(60 * 60 * 24 * 31)

#     # assert token.balanceOf(accounts[0]) == maxs - stakeAmount  - depositOwner
#     # assert boostpool2.totalAmountStaked() == 0
#     # assert token.balanceOf(accounts[0]) == maxs  - depositOwner
