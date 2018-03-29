pragma solidity ^0.4.19;

import "./interface/TokenController.sol";
import "./ESCBCoin.sol";

/**
  *  Copyright 2018, Konstantin Viktorov (EscrowBlock Foundation)
  *  Copyright 2017, Jorge Izquierdo (Aragon Foundation)
  **/

/*

@notice The ESCBCoinPlaceholder contract will take control over the ESCB coin after the sale
        is finalized and before the EscrowBlock Network is deployed.

        The contract allows for ESCBCoin transfers and transferFrom and implements the
        logic for transfering control of the token to the network when the sale
        asks it to do so.
*/

contract ESCBCoinPlaceholder is TokenController {
  address public tokenSale;
  ESCBCoin public token;

  function ESCBCoinPlaceholder(address _sale, address _ESCBCoin) public {
    tokenSale = _sale;
    token = ESCBCoin(_ESCBCoin);
  }

  function changeController(address network) public {
    assert(msg.sender == tokenSale);
    token.changeController(network);
    selfdestruct(network); // network gets all amount
  }

  // In between the sale and the network. Default settings for allowing token transfers.
  function proxyPayment(address _owner) public payable returns (bool) {
    revert();
    return false;
  }

  function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
    return true;
  }

  function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
    return true;
  }
}
