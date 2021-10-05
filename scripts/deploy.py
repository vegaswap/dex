from brownie import VyperStorage, VegaToken, BoostPool, accounts, network


def main():
    # requires brownie account to have been created
    net = network.show_active()
    if net=='development':
        # add these accounts to metamask by importing private key
        owner = accounts[0]
        token = VegaToken.deploy({'from':accounts[0]})
        token.transfer(accounts[1], 100*10**18, {'from':accounts[0]})

        maxy = 10000 * 10 ** 18
        #TODO yield token
        bpool = BoostPool.deploy(
            token.address,
            token.address,
            30,
            1,
            maxy,
            18,
            18,
            1000 * 10 ** 18,
            {"from": accounts[0]},
        )
        print("deployed pool", bpool)
        bpool.activateStaking({"from": accounts[0]})
        # bpool.setReward(15,{"from": accounts[0]})

        # boostpool.stake(1000, 30, {"from": accounts[0]})
    elif net == "bsctest":
        print("net ", net)
        PRIVATEKEY = "da9515202edb5d13aa7e95e9e03ae652f099817488ff413a48c776698c626539"
        accounts.add(PRIVATEKEY)
        # token = VegaToken.deploy({'from':accounts[0]})        
        bal = network.web3.eth.getBalance(accounts[0].address)
        print(accounts[0],": ",bal/10**18)

        # token = VegaToken.deploy({'from':accounts[0]})
        # print(token)
        # token.transfer(accounts[1], 100*10**18, {'from':accounts[0]})
        vegatoken = VegaToken.at("0x8076584601196a6261Fe03366b006E7867edF198")
        print(vegatoken.balanceOf(accounts[0]))
        
        # boostpool = "0xAee1bdf0D313F6B2F0A6627E1Ff81AFb34bBb283"

        # maxy = 10000 * 10 ** 18
        # bpool = BoostPool.deploy(
        #     vegatoken.address,
        #     vegatoken.address,
        #     30,
        #     1,
        #     maxy,
        #     18,
        #     18,
        #     1000 * 10 ** 18,
        #     {"from": accounts[0]},
        # )

        # maxy = 10000 * 10 ** 18
        # #TODO yield token
        # bpool = BoostPool.deploy(
        #     vegatoken,
        #     vegatoken,
        #     30,
        #     maxy,
        #     1000 * 10 ** 18,
        #     18,
        #     18,
        #     {"from": accounts[0]},
        # )
        # print("bpool ", bpool)
        # print(netw)


    # elif network.show_active() == 'kovan':
    #     # add these accounts to metamask by importing private key