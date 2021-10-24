pragma solidity 0.4.24;


// Instantiation
// address
// balance 
// add delay
// add security_keys


contract ReKey {
    // The keyword "public" makes variables
    // accessible from other contracts
    address public minter;
    address public active_address;
    bool public transferred;

    // Events allow clients to react to specific
    // contract changes you declare
    event Transfer(address from, address to, uint amount);

    // Constructor code is only run when the contract
    // is created
    constructor() {
        minter = msg.sender;
        active_address = msg.sender;
        transferred = false;
    }

    // Sends an amount of existing coins
    // from any caller to an address
    function transfer_funds(address private_key) public {
        require(msg.sender == minter);
        require(transferred == false);
        
        for key in security_lists[msg.sender] {
            if (key match private_key) {
                balances[key] += balances[msg.sender];
                balances[msg.sender] = 0;
                active_address = key;
                transferred = true
            }
        }
    }
}