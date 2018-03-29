pragma solidity ^0.4.19;

import '../../../contracts/ESCBCoin.sol';

contract ESCBCoinMock is ESCBCoin {
  event MockNow(uint256 _now);
  uint256 mock_now = 1521115500;

  function ESCBCoinMock (address _tokenFactory) ESCBCoin(_tokenFactory) {}

  function getNow()
  internal
  constant
  returns (uint256) {
    return mock_now;
  }

  function setMockedNow(uint256 _b)
  public {
    mock_now = _b;
    MockNow(_b);
  }
}
