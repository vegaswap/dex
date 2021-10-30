f = 10 ** 18
_rewardSteps = [15, 11, 8, 6, 4]
_stakeSteps = [100 * f, 200 * f, 300 * f, 400 * f]

i = 0
totalr = 0
for x in _stakeSteps:
    r = _rewardSteps[i]
    rw = r * 100 * f
    print(rw)
    i+=1
    totalr += rw

print("total ", totalr/10**18)
p = 0.01
print("total ", p * totalr/10**18)