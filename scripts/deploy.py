from brownie import VyperStorage, VegaToken, BoostPool, accounts, network


def main():
    # requires brownie account to have been created
    if network.show_active()=='development':
        # add these accounts to metamask by importing private key
        owner = accounts[0]
        token = VegaToken.deploy({'from':accounts[0]})
        token.transfer(accounts[1], 100*10**18, {'from':accounts[0]})

        maxy = 10000 * 10 ** 18
        #TODO yield token
        pool = BoostPool.deploy(
            token.address,
            token.address,
            30,
            maxy,
            1000 * 10 ** 18,
            18,
            18,
            {"from": accounts[0]},
        )
        # boostpool.activateStaking({"from": accounts[0]})
        # boostpool.stake(1000, 30, {"from": accounts[0]})

    # elif network.show_active() == 'kovan':
    #     # add these accounts to metamask by importing private key
    #     owner = accounts.load("main")
    #     VyperStorage.deploy({'from':owner})