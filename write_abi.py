import json


def write(ctr):
    with open("./brownie-build/contracts/%s.json"%ctr,"r") as f:

        x = json.loads(f.read())
        print(x.keys())
        abi = x["abi"]
        with open("./abis/%s.abi"%ctr,"w") as g:
            g.write(json.dumps(abi,indent=4))

ctrs = ["VegaToken", "BoostPool"]
for ctr in ctrs:
    write(ctr)