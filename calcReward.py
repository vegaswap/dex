# simulation of reward function

#VGA
# rewardDay = 2
# lockDuration = 30
rewardVGA = 13
priceVGA = 0.015

# rewardTotal = rewardDay * lockDuration
# rewardTotal = 60

yieldAmount = 2000000

yieldUSD = yieldAmount * priceVGA

# print("in USDT ",yieldUSD)
# print("yield ",yieldAmount)

def calc_apy(ROI, days):
    return  -1+(1+ ROI)**(360/days)

def back_calc():
    ROI = 0.1

    apy = calc_apy(ROI, 30)
    maxStake = 1000
    stakeAmount = 1000
    print(ROI, apy)

    stake = 1000
    rewardUSD = ROI * stake
    reward = rewardUSD/priceVGA
    print("reward VGA ", reward)
    print("reward VGA per USD ", reward/stake)

# stakeAmount = 1000
# reward = rewardVGA * stakeAmount
# rewardUSD = reward * priceVGA
# ROI = rewardUSD/stakeAmount
# print(ROI)

back_calc()

# print("reward/day per $ ", (reward/30)/stake)
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


