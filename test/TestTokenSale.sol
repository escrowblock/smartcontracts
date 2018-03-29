pragma solidity ^0.4.19;

import "truffle/Assert.sol";
import "zeppelin/contracts/token/ERC20.sol";
import "../contracts/mocks/helpers/ESCBTokenSaleMock.sol";
import "./mocks/helpers/ThrowProxy.sol";
import "../contracts/mocks/helpers/MultisigMock.sol";
import "../contracts/mocks/helpers/NetworkMock.sol";

contract TestTokenSale {
  uint public initialBalance = 200 finney;
  uint256 minGoal = 10000000000000000000; //10 ETH in weis
  uint256 goal    = 1000000000000000000000; // 1000 ETH in weis
  address factory;

  ThrowProxy throwProxy;

  function beforeAll() {
    factory = address(new MiniMeTokenFactory());
  }

  function beforeEach() {
    throwProxy = new ThrowProxy(address(this));
  }

  function testHasCorrectPriceForStages() {
    ESCBTokenSaleMock sale = new ESCBTokenSaleMock(10, 20, address(this), 3);
    Assert.equal(sale.getPrice(10), 3, "Should have correct price for start stage 1");
    Assert.equal(sale.getPrice(13), 3, "Should have correct price for middle stage 1");
    Assert.equal(sale.getPrice(14), 3, "Should have correct price for final stage 1");
    Assert.equal(sale.getPrice(15), 1, "Should have correct price for start stage 2");
    Assert.equal(sale.getPrice(18), 1, "Should have correct price for middle stage 2");
    Assert.equal(sale.getPrice(19), 1, "Should have correct price for final stage 2");

    Assert.equal(sale.getPrice(9), 0, "Should have incorrect price out of sale");
    Assert.equal(sale.getPrice(20), 0, "Should have incorrect price out of sale");
  }

  function testHasCorrectPriceForMultistage() {
    ESCBTokenSaleMock sale = new ESCBTokenSaleMock(10, 40, address(this), 5);
    Assert.equal(sale.getPrice(10), 5, "Should have correct price");
    Assert.equal(sale.getPrice(19), 5, "Should have correct price");
    Assert.equal(sale.getPrice(20), 3, "Should have correct price");
    Assert.equal(sale.getPrice(25), 3, "Should have correct price");
    Assert.equal(sale.getPrice(30), 1, "Should have correct price");
    Assert.equal(sale.getPrice(39), 1, "Should have correct price");

    Assert.equal(sale.getPrice(9), 0, "Should have incorrect price out of sale");
    Assert.equal(sale.getPrice(41), 0, "Should have incorrect price out of sale");
  }

  function testAllocatesTokensInSale() {
    MultisigMock ms = new MultisigMock();

    ESCBTokenSaleMock sale = new ESCBTokenSaleMock(10, 20, address(ms), 3);
    ms.deployAndSetESCBCoin(sale, minGoal, goal);
    ms.activateSale(sale);

    sale.setMockedNow(12);
    Assert.isTrue(sale.proxyPayment.value(25 finney)(address(this)), 'proxy payment should succeed'); // Gets 5 @ 10 finney
    Assert.equal(sale.totalCollected(), 25 finney, 'Should have correct total collected');

    sale.setMockedNow(17);
    assert(sale.proxyPayment.value(10 finney)(address(this))); // Gets 1 @ 20 finney

    Assert.equal(ERC20(sale.token()).balanceOf(address(this)), 85 finney, 'Should have correct balance after allocation');
    Assert.equal(ERC20(sale.token()).totalSupply(), 85 finney, 'Should have correct supply after allocation');
    Assert.equal(sale.saleWallet().balance, 35 finney, 'Should have sent money to multisig');
    Assert.equal(sale.totalCollected(), 35 finney, 'Should have correct total collected');
  }

  function testCannotGetTokensInNotInitiatedSale() {
    TestTokenSale(throwProxy).throwsWhenGettingTokensInNotInitiatedSale();
    throwProxy.assertThrows("Should have thrown when sale is not activated");
  }

  function throwsWhenGettingTokensInNotInitiatedSale() {
    MultisigMock ms = new MultisigMock();

    ESCBTokenSaleMock sale = new ESCBTokenSaleMock(10, 20, address(ms), 3);
    ms.deployAndSetESCBCoin(sale, minGoal, goal);
    ms.activateSale(sale);
    // Would need activation from this too

    sale.setMockedNow(12);
    sale.proxyPayment.value(50 finney)(address(this));
  }

  function testEmergencyStop() {
    MultisigMock ms = new MultisigMock();
    ESCBTokenSaleMock sale = new ESCBTokenSaleMock(10, 20, address(ms), 3);
    ms.deployAndSetESCBCoin(sale, minGoal, goal);
    ms.activateSale(sale);

    sale.setMockedNow(12);
    Assert.isTrue(sale.proxyPayment.value(15 finney)(address(this)), 'proxy payment should succeed');
    Assert.equal(ERC20(sale.token()).balanceOf(address(this)), 45 finney, 'Should have correct balance after allocation');

    ms.emergencyStopSale(address(sale));
    Assert.isTrue(sale.saleStopped(), "Sale should be stopped");

    ms.restartSale(sale);

    sale.setMockedNow(16);
    Assert.isFalse(sale.saleStopped(), "Sale should be restarted");
    Assert.isTrue(sale.proxyPayment.value(1 finney)(address(this)), 'proxy payment should succeed');
    Assert.equal(ERC20(sale.token()).balanceOf(address(this)), 46 finney, 'Should have correct balance after allocation');
  }

  function testCantBuyTokensInStoppedSale() {
    TestTokenSale(throwProxy).throwsWhenGettingTokensWithStoppedSale();
    throwProxy.assertThrows("Should have thrown when sale is stopped");
  }

  function throwsWhenGettingTokensWithStoppedSale() {
    MultisigMock ms = new MultisigMock();
    ESCBTokenSaleMock sale = new ESCBTokenSaleMock(10, 20, address(ms), 3);
    ms.deployAndSetESCBCoin(sale, minGoal, goal);
    ms.activateSale(sale);
    sale.setMockedNow(12);

    ms.emergencyStopSale(address(sale));
    sale.proxyPayment.value(20 finney)(address(this));
  }

  function testCantBuyTokensInEndedSale() {
    TestTokenSale(throwProxy).throwsWhenGettingTokensWithEndedSale();
    throwProxy.assertThrows("Should have thrown when sale is ended");
  }

  function throwsWhenGettingTokensWithEndedSale() {
    MultisigMock ms = new MultisigMock();
    ESCBTokenSaleMock sale = new ESCBTokenSaleMock(10, 20, address(ms), 3);
    ms.deployAndSetESCBCoin(sale, minGoal, goal);
    ms.activateSale(sale);
    sale.setMockedNow(21);

    sale.proxyPayment.value(20 finney)(address(this));
  }

  function testTokensAreLockedDuringSale() {
    TestTokenSale(throwProxy).throwsWhenTransferingDuringSale();
    throwProxy.assertThrows("Should have thrown transferring during sale");
  }

  function throwsWhenTransferingDuringSale() {
    MultisigMock ms = new MultisigMock();
    ESCBTokenSaleMock sale = new ESCBTokenSaleMock(10, 20, address(ms), 3);
    ms.deployAndSetESCBCoin(sale, minGoal, goal);
    ms.activateSale(sale);
    sale.setMockedNow(12);
    sale.proxyPayment.value(15 finney)(address(this));

    ERC20(sale.token()).transfer(0x1, 10 finney);
  }

  function testTokensAreTransferrableAfterSale() {
    MultisigMock ms = new MultisigMock();
    ESCBTokenSaleMock sale = new ESCBTokenSaleMock(10, 20, address(ms), 3);
    ms.deployAndSetESCBCoin(sale, minGoal, goal);
    ms.activateSale(sale);

    Assert.equal(ESCBCoin(sale.token()).controller(), address(sale), "Sale is controller during sale");

    sale.setMockedNow(12);
    sale.proxyPayment.value(15 finney)(address(this));
    sale.setMockedNow(22);
    ms.finalizeSale(sale);

    Assert.equal(ESCBCoin(sale.token()).controller(), sale.networkPlaceholder(), "Network placeholder is controller after sale");

    ERC20(sale.token()).transfer(0x1, 10 finney);
    Assert.equal(ERC20(sale.token()).balanceOf(0x1), 10 finney, 'Should have correct balance after receiving tokens');
  }

  function testFundsAreTransferrableAfterSale() {
    MultisigMock ms = new MultisigMock();
    ESCBTokenSaleMock sale = new ESCBTokenSaleMock(10, 20, address(ms), 3);
    ms.deployAndSetESCBCoin(sale, minGoal, goal);
    ms.activateSale(sale);

    Assert.equal(ESCBCoin(sale.token()).controller(), address(sale), "Sale is controller during sale");

    sale.setMockedNow(12);
    sale.proxyPayment.value(15 finney)(address(this));
    sale.setMockedNow(22);
    ms.finalizeSale(sale);

    ms.withdrawWallet(sale);
    Assert.equal(ms.balance, 15 finney, "Funds are collected after sale");
  }

  function testFundsAreLockedDuringSale() {
    TestTokenSale(throwProxy).throwsWhenTransferingFundsDuringSale();
    throwProxy.assertThrows("Should have thrown transferring funds during sale");
  }

  function throwsWhenTransferingFundsDuringSale() {
    MultisigMock ms = new MultisigMock();
    ESCBTokenSaleMock sale = new ESCBTokenSaleMock(10, 20, address(ms), 3);
    ms.deployAndSetESCBCoin(sale, minGoal, goal);
    ms.activateSale(sale);

    Assert.equal(ESCBCoin(sale.token()).controller(), address(sale), "Sale is controller during sale");

    sale.setMockedNow(12);
    sale.proxyPayment.value(15 finney)(address(this));
    sale.setMockedNow(22);
    ms.finalizeSale(sale);

    ms.withdrawWallet(sale);
    Assert.equal(ms.balance, 15 finney, "Funds are collected after sale");
  }

  function testNetworkDeployment() {
    MultisigMock devMultisig = new MultisigMock();

    ESCBTokenSaleMock sale = new ESCBTokenSaleMock(10, 20, address(devMultisig), 3);
    devMultisig.deployAndSetESCBCoin(sale, minGoal, goal);
    devMultisig.activateSale(sale);

    Assert.equal(ESCBCoin(sale.token()).controller(), address(sale), "Sale is controller during sale");
    sale.setMockedNow(12);
    sale.proxyPayment.value(15 finney)(address(this));
    sale.setMockedNow(22);
    devMultisig.finalizeSale(sale);

    Assert.equal(ESCBCoin(sale.token()).controller(), sale.networkPlaceholder(), "Network placeholder is controller after sale");

    doTransfer(sale.token());

    devMultisig.deployNetwork(sale, new NetworkMock());

    TestTokenSale(throwProxy).doTransfer(sale.token());
    throwProxy.assertThrows("Should have thrown transferring with network mock");
  }

  function doTransfer(address token) {
    ERC20(token).transfer(0x1, 10 finney);
  }
}
