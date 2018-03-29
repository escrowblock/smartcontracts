pragma solidity ^0.4.19;

contract NetworkMock {
  function proxyPayment(address _owner) payable returns (bool) {
    return false;
  }

  function onTransfer(address _from, address _to, uint _amount) returns (bool) {
    return false;
  }

  function onApprove(address _owner, address _spender, uint _amount) returns (bool) {
    return false;
  }
}
