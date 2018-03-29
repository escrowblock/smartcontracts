pragma solidity ^0.4.19;

import './helpers/ESCBTokenSaleMock.sol';

// @dev ESCBTokenSaleTokenMock for ERC20 tests purpose.
// As it also deploys MiniMeTokenFactory, nonce will increase and therefore will be broken for future deployments

contract ESCBTokenSaleTokenMock is ESCBTokenSaleMock {
  function ESCBTokenSaleTokenMock(address initialAccount, uint256 initialBalance)
    ESCBTokenSaleMock(1521115200, 1552651200, msg.sender, 10000)
    {
      uint256 minGoal = 10000000000000000000; // 10 ETH in weis
      uint256 goal    = 1000000000000000000000; // 1000 ETH in weis
      ESCBCoin token = new ESCBCoin(new MiniMeTokenFactory());
      ESCBCoinPlaceholder networkPlaceholder = new ESCBCoinPlaceholder(this, token);
      token.changeController(address(this));
      setMockedNow(1521005200);
      setESCBCoin(token, networkPlaceholder, new SaleWallet(msg.sender, address(this)), minGoal, goal);
      activateSale();
      setMockedNow(1521415200);
      issueWithExternalFoundation(initialAccount, initialBalance, "from test id: 777");
      setMockedNow(1552651500);
      finalizeSale();

      token.changeVestingWhitelister(msg.sender);
  }
}
