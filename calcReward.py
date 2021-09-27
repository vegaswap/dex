# simulation of reward function

#VGA
rewardDay = 300

lockDuration = 30
priceVGA = 0.015

yieldAmount = 2000000

yieldUSD = yieldAmount * priceVGA

print("in USDT ",yieldUSD)
print("yield ",yieldAmount)

maxStake = 1000

stakeAmount = 1000
for x in range(1000,10000,stakeAmount):
    print("stake ", x)
    reward = rewardDay * lockDuration
    rewardUSD = reward * priceVGA
    ROI = rewardUSD/stakeAmount
    APY = (1+ ROI)**(360/lockDuration)
    print("ROI ", ROI*100)
    print("APY ", APY*100)


