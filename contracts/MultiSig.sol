//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "hardhat/console.sol";

contract MultiSig {
    // Owners, set in contructor
    address[] public owners;
    mapping(address => bool) public isOwner;
    // Threshold of signatures for a transaction to be initiated
    uint public sigThreshold;

    // Transaction structure
    struct Transaction {
        address to; // Who is the reciever of this tx?
        uint value; // For how much?
        bytes data; // Any tx data?
        bool executed; // Has tx been executed
        mapping(address => bool) isConfirmed; // addresses who confirmed the tx.
        uint numConfirmations; // Number of confirmations present in a transaction.
    }
    // Transaction index/ record
    uint256 txIndex;
    // Mapping of the idex/ tx record
    mapping(uint256 => Transaction) transactions;
    
    constructor(address[] memory _owners, uint _sigThreshold) {
        require(_owners.length > 0, "owners required"); // Wallet must have owners
        require(_sigThreshold > 0 && _sigThreshold <= _owners.length, "invalid number of required confirmations"); // Require the sigThreshold set to be a valid input.

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner"); // Valid address
            require(!isOwner[owner], "owner not unique"); // Not already in the array of owners

            isOwner[owner] = true; // add to mapping
            owners.push(owner); // add to array of owners
        }

        sigThreshold = _sigThreshold; // set the signatures threshold for a transaction from this wallet to be initiated
    }

    // Only wallet owners 
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
    // Checks if struct created
    modifier txExists(uint _txIndex) {
        require(transactions[_txIndex].value > 0, "The tx does not exist, or is equal to 0.");
        _;
    }
    // Checks if the transaction has previously been executed
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }
    // Checks whether the transaction is fully executed and confirmed. 
    modifier notConfirmed(uint _txIndex) {
        require(!transactions[_txIndex].isConfirmed[msg.sender], "tx already confirmed");
        _;
    }

    // EVENTS
    //---------
    event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event Deposit(address indexed sender, uint amount, uint balance);

    receive() payable external {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // FUNCTIONS
    //-----------

    // If you are a owner of this wallet, you can initate a transaction
    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
        // increment tx index to the next number/tx
        txIndex++;
        Transaction storage t = transactions[txIndex];
        // Create struct in storage.
        t.to = _to;
        t.value = _value;
        t.data = _data;
        t.executed = false;
        t.numConfirmations = 0;

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    // Function to be called by a single member (wallet address) to approve a transaction.
    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage t = transactions[_txIndex];

        t.isConfirmed[msg.sender] = true;
        t.numConfirmations++;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage t = transactions[_txIndex];

        require(
            t.numConfirmations >= sigThreshold,
            "Cannot execute tx, not enough signatures for approval."
        );

        t.executed = true;

        (bool success, ) = t.to.call{value: t.value}(t.data); 
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage t = transactions[_txIndex];

        require(t.isConfirmed[msg.sender], "Tx not confirmed, you cannot revoke.");

        t.isConfirmed[msg.sender] = false;
        t.numConfirmations--;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getTransaction(uint _txIndex) public view returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
        Transaction storage t = transactions[_txIndex];

        return (t.to, t.value, t.data, t.executed, t.numConfirmations);
    }

    function isConfirmed(uint _txIndex, address _owner) public view returns (bool) {
        Transaction storage t = transactions[_txIndex];

        return t.isConfirmed[_owner];
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return txIndex;
    }

}
