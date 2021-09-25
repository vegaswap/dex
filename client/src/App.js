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
        boostAmount: 0,
        rewardDay: 0,
        rewardDayInput: 0,
        stakeToken: null,
        yieldToken: null
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
        // <=42 to exclude Kovan, <42 to include kovan
        if (this.state.chainid < 42) {
            // Wrong Network!
            return
        }
        console.log(this.state.chainid)
        
        const vegaToken = await this.loadContract(this.state.chainid,"VegaToken")
        const boostPool = await this.loadContract(this.state.chainid,"BoostPool")
        
        const totalSupply = await vegaToken.methods.totalSupply().call()/10**18
        const vgabalance = await vegaToken.methods.balanceOf(this.state.accounts[0]).call()/10**18

        const {web3} = this.state
        const ethbalance = await web3.eth.getBalance(this.state.accounts[0])/10**18;

        const rewardDay = await boostPool.methods.rewardPerDay().call();
        const stakeToken = await boostPool.methods.StakeToken().call();
        const yieldToken = await boostPool.methods.YieldToken().call();

        // console.log("balance " + vgabalance + " ")

        this.setState({
            ethbalance: ethbalance,
            vgabalance: vgabalance,
            totalSupply: totalSupply,
            rewardDay: rewardDay,
            boostPool: boostPool,
            stakeToken: stakeToken,
            yieldToken: yieldToken
        })
    }

    loadContract = async (chain, contractName) => {
        console.log("load " + chain + " " + contractName)
        // Load a deployed contract instance into a web3 contract object
        const {web3} = this.state

        // Get the address of the most recent deployment from the deployment map
        let address
        console.log("load " + contractName + " " + deployMap)
        
        try {
            // address = map[chain][contractName][0]
            // address = deployMap[contractName]
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
        console.log(contractArtifact.abi)

        return new web3.eth.Contract(contractArtifact.abi, address)
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

   

    render() {
        const {
            web3, accounts, chainid,
            totalSupply, vgabalance, ethbalance, boostAmount, rewardDay, rewardDayInput, stakeToken, yieldToken
        } = this.state

        if (!web3) {
            return <div>Loading Web3, accounts, and contracts...</div>
        }

        // <=42 to exclude Kovan, <42 to include Kovan
        if (isNaN(chainid) || chainid < 42) {
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
            <div>VGA balance: {vgabalance}</div>
            <div>ETH balance: {ethbalance}</div>
            <div>rewardDay: {rewardDay}</div>
            <div>Stake Token: {stakeToken}</div>
            <div>Yield Token: {yieldToken}</div>
            
            <br/>
            <form onSubmit={(e) => this.changeVyper(e)}>
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

            <form onSubmit={(e) => this.setReward(e)}>
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
            </form>

            
        </div>)
    }
}

export default App
