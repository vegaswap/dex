from brownie import VyperStorage, VegaToken, BoostPool, accounts, network


def main():
    # requires brownie account to have been created
    net = network.show_active()
    if net=='development':
        # add these accounts to metamask by importing private key
        owner = accounts[0]
        token = VegaToken.deploy({'from':accounts[0]})
        token.transfer(accounts[1], 100*10**18, {'from':accounts[0]})

    elif net == "bsctest":
        VEGA_TOKEN_ADDRESS = "0x3a81fE3E78B612Fd3c3E55944c5f642504236572"
        POOL_TOKEN_ADDRESS = "0x686095a66F4F82032B2fc7408c7F531708676e57"


        # vegatoken = VegaToken.at("0x8076584601196a6261Fe03366b006E7867edF198")
        # boostpool = "0xAee1bdf0D313F6B2F0A6627E1Ff81AFb34bBb283"


    # elif network.show_active() == 'kovan':
    #     # add these accounts to metamask by importing private key