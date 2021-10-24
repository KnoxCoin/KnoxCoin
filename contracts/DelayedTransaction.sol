// pragma solidity 0.4.24;


// contract DelayedTransaction {
//     // The keyword "public" makes variables
//     // accessible from other contracts
//     address public minter;
//     address public to_recieve;
//     uint256 public to_send;
//     uint public time_created;
//     bool public cancelled;
    

//     // Events allow clients to react to specific
//     // contract changes you declare
//     event Sent(address from, address to, uint amount);

//     // Constructor code is only run when the contract
//     // is created
//     constructor(address receiver, uint256 amount) public {
//         minter = msg.sender;
//         time_created = block.timestamp;
//         cancelled = false;
//         to_recieve = receiver;
//         to_send = amount;
//     }

//     // Sends an amount of existing coins
//     // from any caller to an address
//     function transfer_funds(address receiver, uint256 balance, uint delay) public returns (bool) {
//         require(msg.sender == minter);
//         require(block.timestamp > delay + time_created);
//         require(cancelled == false);
//         require(to_recieve == receiver);
        
//         if (to_send > balance) {
//             return false;
//         }

//         // Close off transactioin to prevent it from being reexecuted
//         cancelled = true;
//         return true;
//     }
    
//     // Cancels a transaction
//     function cancel_transaction() public {
//         require(msg.sender == minter);
//         cancelled = true;
//     }
// }