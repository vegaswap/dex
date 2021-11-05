// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

/*
 --- Launchswap: contract for launching ventures ---
 investor submit capital and can redeem it at a cost
 for now this is a single instance of the swap
 the owner of the contract defines the mechanics
 owner defines the mid price and the spread
 users swap at the resulting bid and ask
 in first iteration no liquidity pools
*/
//import "hardhat/console.sol";

import "./erc20.sol";
import "./Pcert.sol";
//import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
//import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

//import "../lib/InitializableOwnable.sol";


//contract LaunchSwap is InitializableOwnable, Context, Initializable {
contract LaunchSwap  {
    
    /*
     * a discrete funding round. only buy price
     */
    struct Round {
        string name;
        uint256 price;
        uint256 cap;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 invested;
        bool whitelisted;
        address[] whitelistedAddresses;
        mapping(address => uint256) investors; //calculate from events emitted?
        mapping(address => uint256) whitelistAmounts; // mapping investor address to max amount of token one can receive in this round.
    }

    // storage
    //TODO : dynamic and ordering?
    // TODO: Should be deploy separatedly
    PCert private pc;
    Round[10] public rounds;
    uint8 public currentRound;
    string public launchName;
    string public launchTicker;

    address public launchTokenAddress;
    address public investTokenAddress;
    address public treasuryAddress;
    address public pcertAddress;
    uint256 public launchTimestamp; // total amount collected for all the participation rounds
    uint256 public totalInvested; // total amount release to treasury
    uint256 public totalReleased;

    // events
    event Invested(
        address participant,
        uint256 amountInvested,
        uint8 round,
        uint256 amountIssued
    );
    event Divested(
        address participant,
        uint256 amountDivested,
        uint8 round,
        uint256 amountRefunded
    );
    event RoundChange(uint8 newRound);
    event TokensRedeemed(address participant, uint256 amountRedeemed);
    event CapitalReleased(uint256 amount);

    function initialize(
        string memory _launchName,
        string memory _launchTicker,
        address _investTokenAddress,
        address _treasuryAddress,
        address _pcertAddress
    )  public     
    {
        launchName = _launchName;
        launchTicker = _launchTicker;
        investTokenAddress = _investTokenAddress;
        treasuryAddress = _treasuryAddress;
        pcertAddress = _pcertAddress;

        currentRound = 0;

        //symbol of future token not reserved yet, so use launchticker is temporary
        // should passing the pcert address instead
        //        string memory pcSymbol = string(abi.encodePacked("pc", launchTicker));
        //        pc = new PCert(pcSymbol);
    }

    /*
     * link the launchtoken
     */
    // function setLaunchToken(address _launchTokenAddress) external onlyOwner {
    //     require(_launchTokenAddress != address(0), "ZERO ADDRESS");

    //     launchTokenAddress = _launchTokenAddress;
    // }

    // function setLaunchTimestamp(uint256 _launchTimestamp) external onlyOwner {
    //     require(
    //         block.timestamp <= _launchTimestamp,
    //         "Cannot launch timestamp in the past."
    //     );

    //     launchTimestamp = _launchTimestamp;
    // }

    // function setRound(
    //     uint8 index,
    //     string calldata name,
    //     uint256 price,
    //     uint256 cap,
    //     uint256 startTimestamp,
    //     uint256 endTimestamp,
    //     bool whitelisted
    // ) external onlyOwner {
    //     require(index > 0, "Round index must start at 1");
    //     require(
    //         startTimestamp < endTimestamp,
    //         "Invalid startTimestamp and endTimestamp"
    //     );

    //     rounds[index].name = name;
    //     rounds[index].price = price;
    //     rounds[index].cap = cap;
    //     rounds[index].startTimestamp = startTimestamp;
    //     rounds[index].endTimestamp = endTimestamp;
    //     rounds[index].whitelisted = whitelisted;
    //     rounds[index].invested = 0;
    // }

    // function getRound(uint8 _index)
    //     public
    //     view
    //     returns (
    //         uint8 index,
    //         string memory name,
    //         uint256 price,
    //         uint256 cap,
    //         uint256 startTimestamp,
    //         uint256 endTimestamp,
    //         uint256 invested
    //     )
    // {
    //     require(_index > 0, "LAUNCHPOOL: NOT_VALID_ROUND");
    //     Round memory r = rounds[_index];

    //     return (
    //         _index,
    //         r.name,
    //         r.price,
    //         r.cap,
    //         r.startTimestamp,
    //         r.endTimestamp,
    //         r.invested
    //     );
    // }

    // function getCurrentRound()
    //     public
    //     view
    //     returns (
    //         uint8 index,
    //         string memory name,
    //         uint256 price,
    //         uint256 cap,
    //         uint256 startTimestamp,
    //         uint256 endTimestamp,
    //         uint256 invested
    //     )
    // {
    //     require(currentRound > 0, "LAUNCHPOOL: FUNDING_NOT_STARTED");
    //     return getRound(currentRound);
    // }

    // // Whitelist address of a round
    // function _roundWhitelistAddress(uint8 roundIdx, address investorAddress)
    //     internal
    // {
    //     require(investorAddress != address(0), "Zero address");

    //     Round storage round = rounds[roundIdx];
    //     round.whitelistedAddresses.push(investorAddress);
    // }

    // // Reset cur
    // function setRoundWhiteList(
    //     uint8 roundIdx,
    //     address[] memory addresses,
    //     uint256[] memory maxInvestAmounts
    // ) external onlyOwner {
    //     require(roundIdx > 0, "LAUNCHPOOL: INVALID_ROUND_INDEX");
    //     require(
    //         addresses.length == maxInvestAmounts.length,
    //         "Addresses and amounts array lengths must match"
    //     );

    //     Round storage round = rounds[roundIdx];

    //     // reset current list
    //     address investorAddress;
    //     for (uint256 i = 0; i < addresses.length; i++) {
    //         investorAddress = addresses[i];
    //         _roundWhitelistAddress(roundIdx, investorAddress);
    //         round.whitelistAmounts[investorAddress] = maxInvestAmounts[i];
    //         // sending out event maybe
    //     }
    // }

    // // Better function would be end current round
    // function startNextRound() external onlyOwner {
    //     currentRound = currentRound + 1;
    //     emit RoundChange(currentRound);
    // }

    // function getCurrentWhiteList() public view returns (address[] memory) {
    //     require(currentRound > 0, "LAUNCHPOOL: FUNDING_NOT_STARTED");

    //     Round storage r = rounds[currentRound];

    //     uint256 k = r.whitelistedAddresses.length;
    //     address[] memory ret = new address[](k);
    //     for (uint256 i = 0; i < k; i++) {
    //         ret[i] = r.whitelistedAddresses[i];
    //     }
    //     return ret;
    // }

    // // Return the amount of whitelisted address of currentRound
    // function getWhiteListAmountCurrentRound(address addr)
    //     public
    //     view
    //     returns (uint256 amount)
    // {
    //     require(currentRound > 0, "LAUNCHPOOL: FUND_NOT_STARTED");
    //     require(addr != address(0), "ZERO ADDRESS");

    //     //require is whitelisted
    //     Round storage r = rounds[currentRound];

    //     return r.whitelistAmounts[addr];
    // }

    // //depositLaunchTokens
    // function depositLaunchTokens(uint256 amount) external onlyOwner {
    //     require(launchTokenAddress != address(0), "invalid address");

    //     ERC20 launchToken = ERC20(launchTokenAddress);

    //     require(
    //         launchToken.allowance(_msgSender(), address(this)) >= amount,
    //         "Please approve amount to deposit"
    //     );
    //     require(
    //         launchToken.balanceOf(_msgSender()) >= amount,
    //         "Insufficient balance to deposit"
    //     );

    //     // Transfer tokens from sender to this contract
    //     launchToken.transferFrom(_msgSender(), address(this), amount);
    // }

    // function investCalculateIssueAmount(
    //     uint256 investAmount,
    //     uint8 investTokenDecimals,
    //     uint256 ask
    // ) public pure returns (uint256) {
    //     //pc decimals 18
    //     //uint8 PC_DECIMALS = 18;
    //     uint256 decimalsDiff = uint256(18 - investTokenDecimals);

    //     // amount / ask (fixed point calc, account for decimal diffs USDC to PC and ask precision)
    //     return
    //         investAmount.mul(10**uint256(investTokenDecimals)).div(ask).mul(
    //             10**decimalsDiff
    //         );
    // }

    // /*
    //  * participate in a funding event
    //  */
    // function invest(uint256 investAmount) external {
    //     require(currentRound > 0, "No valid rounds!");

    //     Round storage r = rounds[currentRound];

    //     //timestamp valid?
    //     require(
    //         block.timestamp >= r.startTimestamp &&
    //             block.timestamp <= r.endTimestamp,
    //         "Current round not within valid time period"
    //     );

    //     //cap reached?
    //     require(
    //         r.invested.add(investAmount) <= r.cap,
    //         "Cap for current round reached"
    //     );

    //     // ???
    //     if (r.whitelisted) {
    //         require(
    //             investAmount <= r.whitelistAmounts[_msgSender()],
    //             "Invest amount has not been whitelisted for current round"
    //         );
    //     }

    //     //e.g. USDC
    //     ERC20 investToken = ERC20(investTokenAddress);

    //     require(
    //         investToken.allowance(_msgSender(), address(this)) >= investAmount,
    //         "Please approve amount to invest"
    //     );
    //     require(
    //         investToken.balanceOf(_msgSender()) >= investAmount,
    //         "Insufficient investtoken balance to invest"
    //     );

    //     uint256 issueAmount =
    //         investCalculateIssueAmount(
    //             investAmount,
    //             investToken.decimals(),
    //             r.price
    //         );

    //     //safetransfer
    //     // Transfer tokens from sender to this contract
    //     investToken.transferFrom(_msgSender(), address(this), investAmount);
    //     //issue PCs
    //     pc.issue(_msgSender(), issueAmount);

    //     r.investors[_msgSender()] = r.investors[_msgSender()].add(investAmount);
    //     r.invested = r.invested.add(investAmount);

    //     totalInvested = totalInvested.add(investAmount);
    //     emit Invested(_msgSender(), investAmount, currentRound, issueAmount);
    // }

    // /**
    //  *  redeem PC to tokens
    //  *  will convert all available PCs to tokens
    //  *  called by investor
    //  */
    // function redeemAtLaunch() external {
    //     require(
    //         launchTimestamp != 0 && block.timestamp >= launchTimestamp,
    //         "Token not launched yet"
    //     );
    //     require(launchTokenAddress != address(0), "launchTokenAddress not set");

    //     uint256 balance = pc.balanceOf(_msgSender());
    //     require(balance > 0, "No Participation credits to redeem");

    //     ERC20 launchToken = ERC20(launchTokenAddress);
    //     require(
    //         launchToken.balanceOf(address(this)) >= balance,
    //         "Insufficient launchtoken contract balance"
    //     );

    //     emit TokensRedeemed(_msgSender(), balance);
    //     // redeem PC and send tokens
    //     pc.redeem(_msgSender(), balance);
    //     //TODO: account for decimals diff
    //     launchToken.transfer(_msgSender(), balance);
    // }

    // /**
    //  * release capital to the treasury address
    //  */
    // function releaseCapital(uint256 amount) external onlyOwner {
    //     ERC20 investToken = ERC20(investTokenAddress);
    //     require(
    //         investToken.balanceOf(address(this)) >= amount,
    //         "Insufficient contract balance to release capital amount"
    //     );

    //     emit CapitalReleased(amount);
    //     investToken.transfer(treasuryAddress, amount);
    //     totalReleased = totalReleased.add(amount);
    // }
}
