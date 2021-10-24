pragma solidity 0.4.24;


contract DelayedTransaction {
    // The keyword "public" makes variables
    // accessible from other contracts
    address public minter;
    unit public time_created;
    bool public cancelled;
    mapping (address => uint) public balances;
    mapping (address => uint256) delays;

    // Events allow clients to react to specific
    // contract changes you declare
    event Sent(address from, address to, uint amount);

    // Constructor code is only run when the contract
    // is created
    constructor() {
        minter = msg.sender;
        time_created = block.timestamp;
        cancelled = false;
    }

    // Sends an amount of existing coins
    // from any caller to an address
    function transfer_funds(address receiver, uint amount) public {
        require(msg.sender == minter);
        require(block.timestamp > delays[msg.sender] + time_created);
        require(cancelled == false);
        
        if (amount > balances[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });
            
        balances[msg.sender] -= amount;
        balances[receiver] += amount;

        // Close off transactioin to prevent it from being reexecuted
        cancelled = true;
        return true;
    }
    
    // Cancels a transaction
    function cancel_transaction() public {
        require(msg.sender == minter);
        cancelled = true;
    }

    // Errors allow you to provide information about
    // why an operation failed. They are returned
    // to the caller of the function.
    error InsufficientBalance(uint requested, uint available);
}