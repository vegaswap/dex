// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;


//import "@openzeppelin/contracts/math/SafeMath.sol";

//import "../lib/InitializableOwnable.sol";

//import "../lib/SafeMath.sol";

/*
Participation certificates (PC)
*/
contract PCert {
    //using SafeMath for uint256;

    // storage
    uint256 public issuedSupply;
    uint8 public decimals; // default to 18
    string public symbol;

    mapping(address => uint256) internal _balances;

    // events
    event Issued(address account, uint256 amount);
    event Redeemed(address account, uint256 amount);

    constructor(string memory _symbol) public {
        issuedSupply = 0;
        symbol = _symbol;
        decimals = 18;
    }

    /*
      Issue an amount bigger than 0 to a non-zero address.
    */
    //public onlyOwner
    function issue(address account, uint256 amount) public {
        require(account != address(0), "zero address");
        require(amount > 0, "amount should be bigger than 0");

        emit Issued(account, amount);
        issuedSupply = issuedSupply + (amount);
        _balances[account] = _balances[account] + (amount);
    }

    //public onlyOwner
    function redeem(address account, uint256 amount) public {
        require(account != address(0), "zero address");
        require(_balances[account] >= amount, "Insufficent balance");

        emit Redeemed(account, amount);
        _balances[account] = _balances[account] - (amount);
        issuedSupply = issuedSupply - (amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0), "zero address");

        return _balances[account];
    }
}
