// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

contract Tradingcredits is Ownable {
    uint256 private _issuedSupply;
    uint8 private _decimals;
    string private _symbol;

    //credit balance: issued - redeemed
    mapping(address => uint256) private _balances;
    //total credits ever issued for an account
    mapping(address => uint256) private _totalissued;

    event Issued(address account, uint256 amount);
    event Redeemed(address account, uint256 amount);

    constructor(string memory __symbol) {
        _symbol = __symbol;
        _decimals = 0;
    }

    // function initialize(string memory symbol) initializer public {
    //     _symbol = symbol;
    //     _decimals = 0;
    //     initialized = true;
    // }

    /// Creates `amount` of credits and assigns them to `account`
    function issue(address account, uint256 amount) public onlyOwner {
        //require(initialized, "Contract not initialized");
        require(account != address(0), "zero address");

        _issuedSupply = _issuedSupply + (amount);
        _balances[account] = _balances[account] + (amount);
        _totalissued[account] = _totalissued[account] + (amount);

        emit Issued(account, amount);
    }

    function redeem(address account, uint256 amount) public onlyOwner {
        //TODO! formula for conversion

        //require(initialized, "Contract not initialized");
        require(account != address(0), "zero address");
        require(_balances[account] >= amount, "Insufficent balance");

        _balances[account] = _balances[account] - (amount);
        _issuedSupply = _issuedSupply - (amount);

        emit Redeemed(account, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _issuedSupply;
    }
}
