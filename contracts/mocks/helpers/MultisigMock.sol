pragma solidity ^0.4.19;

import "./ESCBTokenSaleMock.sol";

contract MultisigMock {
  function deployAndSetESCBCoin(address sale, uint256 minGoal, uint256 goal) {
    ESCBCoin token = new ESCBCoin(new MiniMeTokenFactory());
    ESCBCoinPlaceholder networkPlaceholder = new ESCBCoinPlaceholder(sale, token);
    token.changeController(address(sale));
    ESCBTokenSale s = ESCBTokenSale(sale);
    token.setCanCreateGrants(sale, true);
    s.setESCBCoin(token, networkPlaceholder, new SaleWallet(s.ESCBDevMultisig(), sale), minGoal, goal);
  }

  function activateSale(address sale) {
    ESCBTokenSale(sale).activateSale();
  }

  function emergencyStopSale(address sale) {
    ESCBTokenSale(sale).emergencyStopSale();
  }

  function restartSale(address sale) {
    ESCBTokenSale(sale).restartSale();
  }

  function withdrawWallet(address sale) {
    SaleWallet(ESCBTokenSale(sale).saleWallet()).withdraw();
  }

  function finalizeSale(address sale) {
    ESCBTokenSale(sale).finalizeSale();
  }

  function deployNetwork(address sale, address network) {
    ESCBTokenSale(sale).deployNetwork(network);
  }

  function () payable {}
}
