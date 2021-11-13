pragma solidity ^0.5.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function gift(address target, uint tokens) external returns (bool);
    function cancel(address receiver) external returns (bool);
    function setDelay(address tokenOwner, uint256 delay) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Knox {
    function getStaged() public returns (mapping(address => mapping(uint256 => uint))));
    function cancel(address receiver, uint256 numTokens) public returns (bool);
    function setSecurityCodes(string[] securityCodeHashes) public returns (bool);
    function reKey(message: string, signature: string) public returns (bool);
}


contract KnoxCoin is IERC20, Knox {

    string public constant name = "KnoxCoin";
    string public constant symbol = "KC";
    uint8 public constant decimals = 18;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    // stores security keys. Initiated once, and necessarily distinct
    mapping(address => mapping (string => bool)) securityCodes;
    
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
        require(securityCodes[msg.sender] != 0);

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
    function getStaged() public returns (mapping(address => mapping(uint256 => uint)))) {
        return staged[msg.sender];
    }

    function cancel(address receiver, uint256 numTokens) public returns (bool) {
        staged[msg.sender][receiver][numTokens] = 0;
        return true;
    }

    function setSecurityCodes(string[] securityCodeHashes) public returns (bool) {
        // msg.sender must not have set up codes previously
        require(securityCodes[msg.sender] == 0);
        // must supply at least 5 securityCodeHashes
        require(securityCodeHashes.length >= 5);
        // TODO: securityCodeHashes must be unique
        // TODO: securityCodeHashes must be of some valid character length, but not exceeding a valid character length (analyze for threat model)
        // TODO: securityCodeHashes array must not exceed some valid length

        securityCodes[msg.sender] = securityCodeHashes;
    }

    // When a user wishes to transfer all funds to a secure account specified by a security code, 
    //      the user should supply a message containing the public key associated with that security code
    //      and sign it using the security code. 
    function reKey(message: string, signature: string) public returns (bool) {
        // message must match a security code public key that the user has set
        require(securityCodes[msg.sender][message] == true);

        // reconstruct public key from signature
        address reconstructed = recoverAddress(message, signature);

        // public key from signature must match message (implies user owns security code (private key))
        require(message == reconstructed);

        // transfer all funds to new address denoted by security code public key
        uint256 acctSum = balances[msg.sender];
        balances[msg.sender] = 0;
        balances[reconstructed] = balances[reconstructed].add(balances[msg.sender]);
        emit Transfer(msg.sender, reconstructed, acctSum);
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

library ECDSA {
    // The following functions are adapted from code written by Pavlo Horbonos

    function getSigner(bytes32 message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {  
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "invalid signature 's' value");
        require(v == 27 || v == 28, "invalid signature 'v' value");
        address signer = ecrecover(hashMessage(message), v, r, s);
        require(signer != address(0), "invalid signature");

        return signer;
    }

    function recoverAddress(bytes32 message, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return getSigner(message, v, r, s);
    }
}

contract DEX {

    event Bought(uint256 amount);
    event Sold(uint256 amount);


    IERC20 public token;

    constructor() public {
        token = new KnoxCoin();
    }

    function buy() payable public {
        uint256 amountTobuy = msg.value;
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(msg.sender, amountTobuy);
        emit Bought(amountTobuy);
    }

    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        msg.sender.transfer(amount);
        emit Sold(amount);
    }

}
