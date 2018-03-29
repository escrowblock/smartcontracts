pragma solidity ^0.4.19;

import "./MiniMeIrrVesDivToken.sol";

/**
 * Copyright 2018, Konstantin Viktorov (EscrowBlock Foundation)
 **/

contract ESCBCoin is MiniMeIrrVesDivToken {
  // @dev ESCBCoin constructor just parametrizes the MiniMeIrrVesDivToken constructor
  function ESCBCoin (
    address _tokenFactory
  ) public MiniMeIrrVesDivToken(
    _tokenFactory,
    0x0,            // no parent token
    0,              // no snapshot block number from parent
    "ESCB token",   // Token name
    18,             // Decimals
    "ESCB",         // Symbol
    true            // Enable transfers
    ) {}
}
