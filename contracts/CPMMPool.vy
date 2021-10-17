# @version ^0.2.15
from vyper.interfaces import ERC20

#TODO lpshares
# events
# track transaction history

# import LPShares as lpshares
#invariant pool
# interface LPshare:
#      def mint()
#      def burn()

admin: public(address)
shares: public(HashMap[address, uint256])
poolshares: public(address)
x: public(uint256)
y: public(uint256)
k: public(uint256)
totalShares: public(uint256)
tokenBase: public(address)
tokenQuote: public(address)

# x,y in initial liq
# token transfers
#fees
#add volume traded
#volatility

@external
def __init__(tokenBase: address,tokenQuote: address):
    self.admin = msg.sender
    self.tokenBase = tokenBase
    self.tokenQuote = tokenQuote
    # self.lpshares = new LPShares()

@external
def initLiquidity(x: uint256, y: uint256):
    assert msg.sender == self.admin, "not the admin"
    #TODO deposit
    self.x = x
    self.y = y
    assert ERC20(self.tokenBase).transferFrom(msg.sender, self, x), "transfer base filed"
    assert ERC20(self.tokenQuote).transferFrom(msg.sender, self, y), "transfer quote failed"

    self.shares[msg.sender] = 10000
    self.totalShares = 10000
    self.k = self.x * self.y

@internal
def pricing_CPMM(dx: uint256) -> uint256:
    # constant product MM. price an asset X in Y, by given quantitiy X and Y and delta x
    #TODO fees
    YD: uint256 = self.k / (self.x + dx)
    dy: uint256 = self.y - YD
    return dy

@external
def price(dx: uint256) -> uint256:
    p: uint256 = self.pricing_CPMM(dx)
    return p

@external
def swapIn(dx: uint256):
    dy: uint256 = self.pricing_CPMM(dx)
    assert ERC20(self.tokenBase).allowance(msg.sender, self) >= dx, "not enough allowance"
    assert ERC20(self.tokenBase).transferFrom(msg.sender, self, dx), "transfer failed"
    self.x += dx
    #assert balance
    ERC20(self.tokenQuote).transfer(msg.sender, dy)
    self.y -= dy

@external
def swapOut(dx: uint256):
    dy: uint256 = self.pricing_CPMM(dx)
    assert ERC20(self.tokenBase).allowance(msg.sender, self) >= dx, "not enough allowance"
    assert ERC20(self.tokenBase).transferFrom(msg.sender, self, dx), "transfer failed"
    self.x -= dx
    ERC20(self.tokenQuote).transfer(msg.sender, dy)
    self.y += dy

@external
def addLiq(ix: uint256):
    assert msg.sender == self.admin, "not the admin"
    xPerShare: uint256 = self.x/self.totalShares
    sharesPurchased: uint256 = ix / xPerShare
    #yPerShare: uint256 = self.y/totalShares
    #iy: uint256 = sharesPurchased * yPerShare

    iy: uint256 = ix*(self.y/self.x)

    # transfer ix and iy
    # after done issue shares and adjust pool
    if self.shares[msg.sender] > 0:
        self.shares[msg.sender] += sharesPurchased
    else:
        self.shares[msg.sender] = sharesPurchased

    # update k, curve has moved up
    self.x += ix
    self.y += iy
    self.k = self.x * self.y

@external
def removeLiq(ix: uint256):
    assert msg.sender == self.admin, "not the admin"
    xPerShare: uint256 = self.x/self.totalShares
    sharesRedeem: uint256 = ix / xPerShare

    assert self.shares[msg.sender] > sharesRedeem, "not enough shares to redeem"

    iy: uint256 = ix*(self.y/self.x)

    # transfer ix and iy
    # after done issue shares and adjust pool
    self.shares[msg.sender] -= sharesRedeem

    # update k, curve has moved up
    self.x -= ix
    self.y -= iy
    self.k = self.x * self.y        