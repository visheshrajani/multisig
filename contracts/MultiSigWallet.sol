// SPDX-License-Identifier:MIT

pragma solidity ^0.8.10;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    mapping(address => bool) public isOwner;
    address[] public owners;
    uint public required;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner!");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId >=0 && _txId < transactions.length, "Invalid txId");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }

    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender], "Transaction already approved");
        _;
    }

    constructor(address[] memory _owners, uint _required) public payable {
        require(_owners.length>0,"Length of owners should be greater than 0");
        require(0 < _required && _required <= _owners.length, "Required cannot be 0 or greater than owners length");

        for (uint i; i< _owners.length; i++) {
            address owner = _owners[i];
            require(owner!=address(0),"invalid owner");
            require(!isOwner[owner], "Multiple owner with same address");

            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactions.length -1);
    }

    function approve(uint _txId) 
    external 
    onlyOwner 
    txExists(_txId)
    notExecuted(_txId)
    notApproved(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);

    }

    function _getApprovalCount(uint _txId) private view returns(uint count) {
        for (uint i; i< owners.length; i++){
            if(approved[_txId][owners[i]]) {
                count = count + 1;
            }
        }
    }

    function execute(uint _txId) 
    external
    onlyOwner  
    notExecuted(_txId)
    txExists(_txId)
    {
        require(_getApprovalCount(_txId)>=required, "Not enough approvals");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success,) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Transaction failed!");
        emit Execute(_txId);
        
    }

    function revoke(uint _txId) 
    external
    onlyOwner
    txExists(_txId)
    notExecuted(_txId) 
    {
        require(approved[_txId][msg.sender], "Tx is not approved by you!");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId); 

    }


}