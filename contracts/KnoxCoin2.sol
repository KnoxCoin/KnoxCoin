// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address smart_address, address receiver, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function executeTransaction(address smart_address, address receiver, uint tokens) public returns (bool);
    function cancelTransaction(address smart_address) public returns (bool);
    function setDelay(uint delay) public returns (bool);
    function gift(address target, uint tokens) public returns (bool);
    function current() public view returns (address);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

contract DelayedTransaction {
    // The keyword "public" makes variables
    // accessible from other contracts
    address public minter;
    address public to_recieve;
    uint public to_send;
    uint public time_created;
    bool public cancelled;
    

    // Events allow clients to react to specific
    // contract changes you declare
    event Sent(address from, address to, uint amount);

    // Constructor code is only run when the contract
    // is created
    constructor() public {
        minter = msg.sender;
        time_created = block.timestamp;
        cancelled = false;
    }
    
    function init(address receiver, uint amount) public returns (bool) {
        to_recieve = receiver;
        to_send = amount;
        return true;
    }

    // Sends an amount of existing coins
    // from any caller to an address
    function move_funds(uint delay, uint tokens, address receiver) public returns (bool) {
        require(msg.sender == minter);
        // require(block.timestamp >= delay + time_created);
        // require(tokens == to_send);
        // require(receiver == to_recieve);
        // require(cancelled == false);

        // Close off transactioin to prevent it from being reexecuted
        cancelled = true;
        return true;
    }
    
    // Cancels a transaction
    function cancel_transaction() public {
        require(msg.sender == minter);
        cancelled = true;
    }
}


contract KnoxCoin2 is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    // Can set up function that does one time setup
    mapping (address => uint256) delays;
    
    mapping (address => DelayedTransaction) transactions;
    
    // {pkey1: [pk2, pk3, pk4], pkey2: [pk2, pk3, pk4], pkey3: [pk2, pk3, pk4],}
    mapping (address => address[]) public security_lists;

    uint256 totalSupply_;
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "KnoxCoin2";
        symbol = "KC";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        delays[msg.sender] = 0;
        // security_lists[msg.sender] = null;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address smart_address, address receiver, uint tokens) public returns (bool) {
        // require(tokens <= balances[msg.sender]);
        
        DelayedTransaction dt = DelayedTransaction(smart_address);
        transactions[smart_address] = dt;
        smart_address.call(abi.encodeWithSignature("init(address, uint)", receiver, tokens));
        return true;
        
    }
    
    function executeTransaction(address smart_address, address receiver, uint tokens) public returns (bool) {
        (bool success, bytes memory result) = smart_address.call(abi.encodeWithSignature("move_funds(uint, uint, address)", delays[msg.sender], tokens, receiver));
        // emit AddedValuesByCall(a, b, success);
        bool valid = abi.decode(result, (bool));
        if (valid) {
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            balances[receiver] = safeAdd(balances[receiver], tokens);
            emit Transfer(msg.sender, receiver, tokens);
            return true;
        }
        return false;
    }
    
    function cancelTransaction(address smart_address) public returns (bool) {
        smart_address.call(abi.encodeWithSignature("cancel_transaction()"));
        return true;
    }
    
    function setDelay(uint delay) public returns (bool) {
        delays[msg.sender] = delay;
    }
    
    function gift(address target, uint tokens) public returns (bool) {
        balances[target] = safeAdd(balances[target], tokens);
    }
    
    function current() public view returns (address) {
        return msg.sender;
    }

    
    // function rekey(address key) public {
    //     rekey = ReKey();
    //     rekey.transfer_funds(key, security_lists[msg.sender]);
    // }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}
