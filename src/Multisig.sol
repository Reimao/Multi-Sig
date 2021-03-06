// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <=0.9.0;

contract Multisig {
  
  struct Transaction {
    address to;
    uint256 value;
    bytes data;
    bool executed;
  }

  address[] public signers;
  mapping(address => bool) public isSigner;
  uint8 public requiredSignatures;
  Transaction[] public transactions;
  mapping(uint32 => mapping(address => bool)) public hasSigned;
  
  event Deposit(address indexed _from, uint256 indexed _value);
  event Initialize(uint32 indexed _id, address indexed _creator);
  event Sign(uint32 indexed _id, address indexed _signer);
  event Unsign(uint32 indexed _id, address indexed _signer);
  event Execute(uint32 indexed _id, address _executor);

  modifier notExecuted(uint32 id) {
    require(!transactions[id].executed, "This transactin was already executed");
    _;
  }

  modifier onlySigner() {
    require(isSigner[msg.sender], "Not a signer of this multisig");
    _;
  }

  modifier transactionExists(uint32 _id) {
    require(_id < transactions.length, "Transactions does not exist");
    _;
  }

  constructor(
    address[] memory _signers,
    uint8 _requiredSignatures
  ) payable {
    require(_requiredSignatures > 0 && _requiredSignatures <= _signers.length, "Invalid required signatures amount");
    
    requiredSignatures = _requiredSignatures;

    for (uint8 i = 0; i < _signers.length; i++) {
      require(_signers[i] != address(0), "Zero address can't be a signer");
      require(!isSigner[_signers[i]], "Encountered signer redudancy");

      isSigner[_signers[i]] = true;
      signers.push(_signers[i]);
    }

  }

  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }

  function getSigners() public view returns (address[] memory) {
    return signers;
  }

  function signersCount() public view returns (uint256) {
    return signers.length;
  }

  function getTransactions() public view returns (Transaction[] memory) {
    return transactions;
  }

  function balance() public view returns (uint256) {
    return address(this).balance;
  }

  function initializeTransaction(
    address _to,
    uint256 _value,
    bytes calldata _data
  )  public onlySigner {
    
    transactions.push(Transaction(_to, _value, _data, false));
    emit Initialize(uint32(transactions.length - 1), msg.sender);
  }

  function signTransaction(uint32 _id) public onlySigner transactionExists(_id) notExecuted(_id) {
    
    hasSigned[_id][msg.sender] = true;
    emit Sign(_id, msg.sender);
  }

  function unsignTransaction(uint32 _id) public onlySigner transactionExists(_id) notExecuted(_id) {
    mapping(uint32 => mapping(address => bool)) storage _hasSigned = hasSigned;
    require(_hasSigned[_id][msg.sender], "Not signed");

    _hasSigned[_id][msg.sender] = false;
    emit Unsign(_id, msg.sender);
  }

  function isApproved(uint32 _id) public view transactionExists(_id) returns (bool) {
    uint256 counter;

    for(uint8 i = 0; i < signers.length; i++) {
      if(hasSigned[_id][signers[i]])
        counter++;
    }

    if(counter >= requiredSignatures)
     return true;

   return false;
  }

  function executeTransaction(uint32 _id) public onlySigner transactionExists(_id) notExecuted(_id) returns (bytes memory){
    require(isApproved(_id), "Not sufficient signatures");
    
    Transaction storage transaction = transactions[_id];
    transaction.executed = true;

    (bool success, bytes memory data) = transaction.to.call{value: transaction.value}(transaction.data);
    require(success, "Transaction failed");

    emit Execute(_id, msg.sender);
    
    return data;
  }
}
