pragma solidity ^0.4.19;

import '../../contracts/interface/ApproveAndCallFallBack.sol';
import "zeppelin/contracts/token/StandardToken.sol";

contract TokenReceiverMock is ApproveAndCallFallBack {
  bytes public extraData;
  uint public tokenBalance;

  function receiveApproval(address _from, uint256 _amount, address _token, bytes _data) {
    StandardToken(_token).transferFrom(_from, this, _amount);

    tokenBalance = StandardToken(_token).balanceOf(this);
    extraData = _data;
  }
}
