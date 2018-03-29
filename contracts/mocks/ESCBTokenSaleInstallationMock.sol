pragma solidity ^0.4.19;

import './helpers/ESCBTokenSaleMock.sol';
import './helpers/ESCBCoinMock.sol';

contract ESCBTokenSaleInstallationMock is ESCBTokenSaleMock {
  ESCBCoin token;
  SaleWallet sWallet;
  function ESCBTokenSaleInstallationMock()
    ESCBTokenSaleMock(1521115200, 1552651200, msg.sender, 10000)
    {
      uint256 minGoal = 10000000000000000000; // 10 ETH in weis
      uint256 goal    = 1000000000000000000000; // 1000 ETH in weis
      token = new ESCBCoinMock(new MiniMeTokenFactory());
      ESCBCoinPlaceholder networkPlaceholder = new ESCBCoinPlaceholder(this, token);
      token.changeController(address(this));
      setMockedNow(1521005200);
      setESCBCoin(token, networkPlaceholder, new SaleWallet(msg.sender, address(this)), minGoal, goal);
      activateSale();
    }

  function mockedFinalize(address newController)
           public {
    setMockedNow(1552651500);
    finalizeSale();
    deployNetwork(newController);
  }

}
