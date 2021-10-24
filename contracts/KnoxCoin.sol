// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// import DelayedTransaction;
// import ReKey;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract KnoxCoin is IERC20 {

    string public constant name = "KnoxCoin";
    string public constant symbol = "KNC";
    uint8 public constant decimals = 18;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    // Can set up function that does one time setup
    mapping (address => uint256) delays;
    
    // mapping (address => DelayedTransaction[]) transactionlist;
    
    // {pkey1: [pk2, pk3, pk4], pkey2: [pk2, pk3, pk4], pkey3: [pk2, pk3, pk4],}
    mapping (address => address[]) public security_lists;

    uint256 totalSupply_ = 1000000000;

    using SafeMath for uint256;

    constructor(uint256 total) public {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
        delays[msg.sender] = 0;
        security_lists[msg.sender] = [msg.sender];
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    // function transfer(address receiver, uint256 numTokens) public override returns (bool) {
    //     require(numTokens <= balances[msg.sender]);
        
    //     if (true) {
    //         balances[msg.sender] -= numTokens;
    //         balances[receiver] += numTokens;
    //     }
        
    //     emit Transfer(msg.sender, receiver, numTokens);
        
    //     return true;
    //     // transaction = DelayedTransaction();
    //     // // If true, emit transfer event
    //     // value = transaction.transfer_funds(reciever, numTokens, balances, delays[msg.sender]);
    //     // if (value) {
    //     //     emit Transfer(msg.sender, receiver, numTokens);
    //     //     return true;
    //     // }
    // }
    
    // function execute() public {
        
    // }
    
    // function cancelTransaction(DelayedTransaction transaction) public {
    //     transaction.cancel_transaction();
    // }
    
    // function rekey(address key) public {
    //     rekey = ReKey();
    //     rekey.transfer_funds(key, security_lists[msg.sender]);
    // }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
