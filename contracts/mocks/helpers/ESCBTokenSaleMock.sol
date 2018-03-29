pragma solidity ^0.4.19;

import '../../../contracts/ESCBTokenSale.sol';

// @dev ESCBTokenSaleMock mocks current block time

contract ESCBTokenSaleMock is ESCBTokenSale {
  uint mock_now = 1521115200;
  event getNowEvent(uint number);
  function ESCBTokenSaleMock (
      uint _initialTime,
      uint _controlTime,
      address _ESCBDevMultisig,
      uint256 _price
  ) ESCBTokenSale(_initialTime, _controlTime, _ESCBDevMultisig, _price) {}

  function getNow() constant internal returns (uint) {
    getNowEvent(mock_now);
    return mock_now;
  }

  function getMockedNow() constant public returns (uint) {
    return mock_now;
  }

  function setMockedNow(uint256 _b) public {
    mock_now = _b;
  }

  function setMockedTotalCollected(uint _totalCollected) {
    totalCollected = _totalCollected;
  }
}
