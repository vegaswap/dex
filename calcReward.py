# simulation of reward function

#VGA
rewardDay = 2
lockDuration = 30
priceVGA = 0.015

rewardTotal = rewardDay * lockDuration

yieldAmount = 2000000

yieldUSD = yieldAmount * priceVGA

# print("in USDT ",yieldUSD)
# print("yield ",yieldAmount)

def apy(ROI, days):
    return  -1+(1+ ROI)**(360/days)

print(apy(0.2, 30))
maxStake = 1000
stakeAmount = 1000

ROI = 0.2

# reward = rewardDay * lockDuration * stakeAmount
# reward = rewardTotal * stakeAmount
# rewardUSD = reward * priceVGA
# ROI = rewardUSD/stakeAmount
# APY = (1+ ROI)**(360/lockDuration)
# print("ROI ", ROI*100)
# print("APY ", APY*100)

# stakeAmount = 1000
# for x in range(1000,10000,stakeAmount):
#     print("stake ", x)
#     reward = rewardDay * lockDuration
#     rewardUSD = reward * priceVGA
#     ROI = rewardUSD/stakeAmount
#     APY = (1+ ROI)**(360/lockDuration)
#     print("ROI ", ROI*100)
#     print("APY ", APY*100)


