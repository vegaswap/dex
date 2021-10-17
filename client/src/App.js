import React, {Component} from "react"
import './App.css'
import {getWeb3} from "./getWeb3"
import deployMap from "./abis/deployMap.json"
import {getEthereum} from "./getEthereum"


class App extends Component {

    state = {
        web3: null,
        accounts: null,
        chainid: null,
        
        totalSupply: 0,
        vgabalance: 0,
        ethbalance: 0,
        vegaToken: null,
        boostPool: null,
        boostPoolAddress: null,
        stakeToken: null,
        yieldToken: null,
        stake: null,
        yieldTotal: 0,
        boostAmount: 0,
        rewardDay: 0,
        rewardDayInput: 0,        
        poolAllowance: 0,
        totalAmountStaked: 0
    }

    componentDidMount = async () => {

        // Get network provider and web3 instance.
        const web3 = await getWeb3()

        // Try and enable accounts (connect metamask)
        try {
            const ethereum = await getEthereum()
            ethereum.enable()
        } catch (e) {
            console.log(`Could not enable accounts. Interaction with contracts not available.
            Use a modern browser with a Web3 plugin to fix this issue.`)
            console.log(e)
        }

        // Use web3 to get the user's accounts
        const accounts = await web3.eth.getAccounts()

        // Get the current chain id
        const chainid = parseInt(await web3.eth.getChainId())

        this.setState({
            web3,
            accounts,
            chainid
        }, await this.loadInitialContracts)

    }

    loadInitialContracts = async () => {
        const {web3} = this.state
        const accounts = await web3.eth.getAccounts()

        // <=42 to exclude Kovan, <42 to include kovan
        // if (this.state.chainid < 42) {
        //     return
        // }
        console.log(this.state.chainid)
        
        const vegaToken = await this.loadContract(this.state.chainid,"VegaToken")
        const boostPool = await this.loadContract(this.state.chainid,"BoostPool")
        
        // for (let key in boostPool) {
        //     console.log(key, boostPool[key]);
        //   }
        const totalSupply = await vegaToken.methods.totalSupply().call()/10**18
        const vgabalance = await vegaToken.methods.balanceOf(this.state.accounts[0]).call()/10**18
        
        const ethbalance = await web3.eth.getBalance(this.state.accounts[0])/10**18;

        const rewardDay = await boostPool.methods.rewardPerDay().call();
        const stakeToken = await boostPool.methods.StakeToken().call();
        const yieldToken = await boostPool.methods.YieldToken().call();
        const totalAmountStaked = await boostPool.methods.totalAmountStaked().call();
        const yieldTotal = await boostPool.methods.yieldTotal().call()/10**18;
        const stake = await boostPool.methods.stakes(this.state.accounts[0]).call();        

        const poolAllowance = await vegaToken.methods.allowance(accounts[0], boostPool._address).call()/10**18;

        // console.log("balance " + vgabalance + " ")

        this.setState({
            ethbalance: ethbalance,
            vgabalance: vgabalance,
            totalSupply: totalSupply,
            rewardDay: rewardDay,
            boostPool: boostPool,
            boostPoolAddress: boostPool._address,
            poolAllowance: poolAllowance,
            vegaToken: vegaToken,
            stakeToken: stakeToken,
            yieldToken: yieldToken,
            totalAmountStaked: totalAmountStaked,
            stake: stake[1],
            yieldTotal: yieldTotal
        })
    }

    loadContract = async (chain, contractName) => {
        console.log("load " + chain + " " + contractName)
        // Load a deployed contract instance into a web3 contract object
        const {web3} = this.state

        // Get the address of the most recent deployment from the deployment map
        let address
        
        try {
            
            address = deployMap[chain][contractName]
        } catch (e) {
            console.log(`Couldn't find any deployed contract "${contractName}" on the chain "${chain}".`)
            return undefined
        }

        // Load the artifact with the specified address
        let contractArtifact
        try {
            // contractArtifact = await import(`./artifacts/deployments/${chain}/${address}.json`)
            contractArtifact = await import(`./abis/${contractName}.json`)
        } catch (e) {
            console.log(`Failed to load contract ${contractName} ${chain} ${address}`)
            return undefined
        }

        let ctr = new web3.eth.Contract(contractArtifact.abi, address)
        console.log(">>> loaded " + address + " " + contractName + " " + ctr)
        return ctr;
    }


    setReward = async (e) => {
        const {accounts, boostPool, rewardDayInput} = this.state
        console.log("set reward")
        e.preventDefault()
        const value = parseInt(rewardDayInput)
        if (isNaN(value)) {
            alert("invalid value")
            return
        }
        //todo this account
        await boostPool.methods.setReward(value).send({from: accounts[0]})
            .on('receipt', async () => {
                this.setState({
                    rewardDay: await boostPool.methods.rewardPerDay().call()
                })
            })       
    }

    approve = async (e) => {
        const {accounts, boostPool, vegaToken} = this.state
        console.log("set reward")
        e.preventDefault()
        // const value = parseInt(rewardDayInput);
        // let amount = 10**6*10**18;
        let account = accounts[0];
        let bal = await vegaToken.methods.balanceOf(account).call();
        console.log(bal);
        let amount = bal;
        // let amount = 100;
        await vegaToken.methods.approve(boostPool._address, amount).send({from: account})        
        //  }).on('transactionHash', (transactionHash) => {
        //  }).on('receipt', (receipt) => {
        //  }).on('confirmation', (confirmationNumber, receipt) => {         
            .on('receipt', async () => {
                this.setState({
                    // poolAllowance: await vegaToken.methods.allowance(account, boostPool._address).call()
                })
            }) 
            .then((instance) => {
                console.log(">! " + instance.status);
                // let address = instance.options.address;
            }).catch((error) => {
                console.log("error " + error);
            });
    }

    boost = async (e) => {
        const {accounts, boostPool, boostAmount} = this.state
        console.log("boost " + boostAmount)
        e.preventDefault()
        
        let account = accounts[0];
        let duration = 30;
        let amount = boostAmount;
        await boostPool.methods.stake(amount, duration).send({from: account})
            .on('receipt', async (e) => {
                console.log("staked..")
                console.log(e.transactionHash)
                // this.setState({
                //     poolAllowance: await boostPool.methods.allowance(account, boostPool._address).call()
                // })
            })
            .catch((error) => {
                console.log("error " + error);
            });     
    }



    render() {
        const {
            web3, accounts, chainid,
            totalSupply, vgabalance, ethbalance, stake, yieldTotal,
            vegaToken, boostPool, boostPoolAddress, stakeToken, yieldToken,
            boostAmount, rewardDay, rewardDayInput, poolAllowance, totalAmountStaked
        } = this.state

        if (!web3) {
            return <div>Loading Web3, accounts, and contracts...</div>
        }

        // <=42 to exclude Kovan, <42 to include Kovan
        // if (isNaN(chainid) || chainid < 42) {
        if (isNaN(chainid)) {
            return <div>Wrong Network! Switch to your local RPC "Localhost: 8545" in your Web3 provider (e.g. Metamask)</div>
        }

        const isAccountsUnlocked = accounts ? accounts.length > 0 : false

        return (<div className="App">
            <h1>Boost pool</h1>
            {
                !isAccountsUnlocked ?
                    <p><strong>Connect with Metamask and refresh the page to
                        be able to edit the storage fields.</strong>
                    </p>
                    : null
            }            

            <div>Total supply: {totalSupply}</div>
            <div>account: {accounts[0]}</div>
            {/* <div>boost pool address: {boostPool._address}</div> */}
            <div>boost pool address: {boostPoolAddress}</div>
            <div>yieldTotal: {yieldTotal}</div>
            <div>VGA balance: {vgabalance}</div>
            <div>ETH balance: {ethbalance}</div>
            <div>staked: {stake}</div>
            <div>rewardDay: {rewardDay}</div>
            <div>Stake Token: {stakeToken}</div>
            <div>Yield Token: {yieldToken}</div>
            <div>poolAllowance:  {poolAllowance}</div>
            <div>totalAmountStaked:  {totalAmountStaked}</div>
            
            <br/>
            <form onSubmit={(e) => this.approve(e)}>
                <div>
                    <button type="submit" disabled={!isAccountsUnlocked}>Approve</button>
                </div>
            </form>
            <br/>

            <form onSubmit={(e) => this.boost(e)}>
                <div>
                    <label>Stake amount</label>
                    <br/>
                    <input
                        name="boostAmount"
                        type="text"
                        value={boostAmount}
                        onChange={(e) => this.setState({boostAmount: e.target.value})}
                    />
                    <br/>
                    <button type="submit" disabled={!isAccountsUnlocked}>Submit</button>
                </div>
            </form>
            <br/>

            {/* <form onSubmit={(e) => this.setReward(e)}>
                <div>
                    <label>Change reward to: </label>
                    <br/>
                    <input
                        name="rewardDay"
                        type="text"
                        value={rewardDayInput}
                        onChange={(e) => this.setState({rewardDayInput: e.target.value})}
                    />
                    <br/>
                    <button type="submit" disabled={!isAccountsUnlocked}>Submit</button>
                </div>
            </form> */}

            
        </div>)
    }
}

export default App
