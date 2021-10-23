pragma solidity 0.8.7;

const { EAC, Util } = require('@ethereum-alarm-clock/lib');
const moment = require('moment');

const web3 = Util.getWeb3FromProviderUrl('ws://localhost:8545');

const eac = new EAC(web3);

async function scheduleTransaction() {
    const receipt = await eac.schedule({
        toAddress: '0xe87529A6123a74320e13A6Dabf3606630683C029',
        windowStart: moment().add('1', 'day').unix() // 1 day from now
    });

    console.log(receipt);
}

scheduleTransaction();

contract DelayedTransaction {

    // Declare state variables of the contract
    address public owner;
    mapping (address => uint) public cupcakeBalances;

    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = msg.sender;
        cupcakeBalances[address(this)] = 100;
    }

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public {
        require(msg.sender == owner, "Only the owner can refill.");
        cupcakeBalances[address(this)] += amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >= amount * 1 ether, "You must pay at least 1 ETH per cupcake");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;
    }
}
