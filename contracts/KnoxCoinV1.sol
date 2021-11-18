pragma solidity ^0.5.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function gift(address target, uint tokens) external returns (bool);
    function setDelay(address tokenOwner, uint256 delay) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Abstract contract (similar to interface)
contract KnoxInterface {
    function cancel(address receiver, uint256 numTokens) public payable returns (bool);
    function setSecurityCodesAndDelay(address[] memory secureAddresses, uint256 delayInMs) public payable returns (bool);
    function reKey(address relatedPublicKey) public payable returns (bool);
}


contract KnoxCoin is IERC20, KnoxInterface {

    string public constant name = "KnoxCoin";
    string public constant symbol = "KC";
    uint8 public constant decimals = 18;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    // stores security keys. Initiated once, and necessarily distinct
    mapping(address => mapping (address => bool)) securityCodes;
    mapping(address => bool) hasSetSecurityCodes;
    
    // stores mapping of sender -> intended recipient -> intended numTokens
    mapping(address => mapping(address => mapping(uint256 => uint))) staged;  
    
    mapping(address => uint256) delays;
    
    uint256 totalSupply_ = 1000 ether;

    using SafeMath for uint256;

    constructor() public {
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function setDelay(address tokenOwner, uint256 delay) public returns (bool) {
        delays[tokenOwner] = delay;
        return true;
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        // for any transaction to occur, user must have set up security codes
        // TODO: could this prevent funds from initially flowing into account?
        // TODO: verify this is actually set to 0 and not ''
        // user must have set security codes previously
        require(hasSetSecurityCodes[msg.sender] == true);

        // user must have enough in balance
        require(numTokens <= balances[msg.sender]);
        
        // user has staged transfer, i.e. has invoked transfer function previously with the same receiver and numTokens, 
        //      storing the timestamp of their invocation at staged[msg.sender][receiver][numTokens]
        if (staged[msg.sender][receiver][numTokens] != 0) {

            // check whether delay has passed since initial invocation
            if (block.timestamp > staged[msg.sender][receiver][numTokens] + delays[msg.sender]) {
                
                // execute transfer
                balances[msg.sender] = balances[msg.sender].sub(numTokens);
                balances[receiver] = balances[receiver].add(numTokens);

                emit Transfer(msg.sender, receiver, numTokens);
                staged[msg.sender][receiver][numTokens] = 0;
            }
        } else {
            staged[msg.sender][receiver][numTokens] = block.timestamp;
        }
        
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }
    
    function gift(address target, uint tokens) public returns (bool) {
        balances[target] = balances[target].add(tokens);
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        // for any transaction to occur, user must have set up security codes
        // TODO: could this prevent funds from initially flowing into account?

        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    // custom (non-ERC20) functions
    function cancel(address receiver, uint256 numTokens) public payable returns (bool) {
        staged[msg.sender][receiver][numTokens] = 0;
        return true;
    }

    function setSecurityCodesAndDelay(address[] memory secureAddresses, uint256 delayInMs) public payable returns (bool) {
        // msg.sender must not have set up codes previously
        require(hasSetSecurityCodes[msg.sender] == false);
        // must supply both secureAddresses and a delayInMs
        require(secureAddresses.length > 0 && delayInMs != 0);
        // must supply at least 5 securityCodeHashes
        // require(secureAddresses.length >= 5);
        // TODO: delayInMs must be at least some minimum time
        // TODO: securityCodeHashes must be unique
        // TODO: securityCodeHashes must be of some valid character length, but not exceeding a valid character length (analyze for threat model)
        // TODO: securityCodeHashes array must not exceed some valid length

        for(uint i=0; i<secureAddresses.length; i++){
            securityCodes[msg.sender][secureAddresses[i]] = true;
        }
        delays[msg.sender] = delayInMs;
        
        hasSetSecurityCodes[msg.sender] = true;
        return true;
    }

    // When a user wishes to transfer all funds to a secure account specified by a security code, 
    //      the user should supply a message containing the public key associated with that security code
    //      and sign it using the security code. 
    function reKey(address relatedPublicKey) public payable returns (bool) {
        // message must match a security code public key that the user has set
        require(securityCodes[relatedPublicKey][msg.sender] == true);

        // transfer all funds to address from related public key
        uint256 acctSum = balances[relatedPublicKey];
        balances[msg.sender] = balances[msg.sender].add(balances[relatedPublicKey]);
        balances[relatedPublicKey] = 0;
        emit Transfer(relatedPublicKey, msg.sender, acctSum);
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