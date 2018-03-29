import {BigNumber} from 'bignumber.js';
BigNumber.config({ ERRORS: false });

const ESCBTokenSaleInstallationMock = artifacts.require("./mocks/ESCBTokenSaleInstallationMock.sol");
const ESCBCoinMock = artifacts.require("./mocks/ESCBCoinMock.sol");
const saleWallet = artifacts.require("saleWallet.sol");
const assertFail = require("./helpers/assertFail");

contract('Refund', function (accounts) {

  const ONEETHER  = 1000000000000000000;
  const gasPrice = 0;

  let token;
  let sale;
  let wallet;
  let addressWallet;
  beforeEach(async () => {
    sale = await ESCBTokenSaleInstallationMock.new();
    token = ESCBCoinMock.at(await sale.token());
    addressWallet = await sale.saleWallet();
    wallet = saleWallet.at(addressWallet);
  })

  it("sale is activated", async () => {
    assert.equal(await sale.isActivated(), true, "sale is activated");
  });

  it("sale is on", async () => {
    await sale.setMockedNow(1521515200);
    assert.equal(await sale.initialTime(), 1521115200, "sale initialTime is 1521115200");
    assert.equal(await sale.getMockedNow(), 1521515200, "sale time is 1521515200");
  });

  it("wallet is active", async () => {
    assert.equal(await wallet.currentState(), "0", "SaleWallet is Active");
  });

  // =========================================================================
  it("tokens are transfered and refunded", async () => {
    await sale.setMockedNow(1521515200);

    //Generate some token balances
    await web3.eth.sendTransaction({ from: accounts[1], to: sale.address, value: 1 * ONEETHER, gas:520000 });
    assert.equal(await web3.eth.getBalance(addressWallet).toNumber(), 1 * ONEETHER, "SaleWallet balance is 1 ETH");
    assert.equal(await wallet.deposited(accounts[1]), 1 * ONEETHER, "Deposit for 1 is 1 ETH");

    await web3.eth.sendTransaction({ from: accounts[2], to: sale.address, value: 3 * ONEETHER, gas:520000 });
    assert.equal(await web3.eth.getBalance(addressWallet).toNumber(), 4 * ONEETHER, "SaleWallet balance is 4 ETH");
    assert.equal(await wallet.deposited(accounts[2]), 3 * ONEETHER, "Deposit for 2 is 3 ETH");

    await web3.eth.sendTransaction({ from: accounts[4], to: sale.address, value: 4 * ONEETHER, gas:520000 });
    assert.equal(await web3.eth.getBalance(addressWallet).toNumber(), 8 * ONEETHER, "SaleWallet balance is 8 ETH");
    assert.equal(await wallet.deposited(accounts[4]), 4 * ONEETHER, "Deposit for 4 is 4 ETH");

    //Finalize Sale
    await sale.mockedFinalize(accounts[0]);

    //Enable refunds
    await wallet.enableRefunds({from: accounts[0]});

    //Claim refunds
    var beforeBalanceOne = new BigNumber(await web3.eth.getBalance(accounts[1]));
    var beforeBalanceTwo = new BigNumber(await web3.eth.getBalance(accounts[2]));
    var beforeBalanceFour = new BigNumber(await web3.eth.getBalance(accounts[4]));
    var txId1 = await sale.claimRefund({from: accounts[1], gasPrice: gasPrice, gas:520000});
    var txId2 = await sale.claimRefund({from: accounts[2], gasPrice: gasPrice, gas:520000});
    var txId4 = await sale.claimRefund({from: accounts[4], gasPrice: gasPrice, gas:520000});
    var afterBalanceOne = new BigNumber(await web3.eth.getBalance(accounts[1]));
    var afterBalanceTwo = new BigNumber(await web3.eth.getBalance(accounts[2]));
    var afterBalanceFour = new BigNumber(await web3.eth.getBalance(accounts[4]));
    var gasCostTxId1 = txId1.receipt.gasUsed * gasPrice;
    var gasCostTxId2 = txId2.receipt.gasUsed * gasPrice;
    var gasCostTxId4 = txId4.receipt.gasUsed * gasPrice;

    assert.equal(beforeBalanceOne.add(1 * ONEETHER).sub(gasCostTxId1).toNumber(), afterBalanceOne.toNumber(), "account_1 should refund 1 ETH");
    assert.equal(beforeBalanceTwo.add(3 * ONEETHER).sub(gasCostTxId2).toNumber(), afterBalanceTwo.toNumber(), "account_2 should refund 3 ETH");
    assert.equal(beforeBalanceFour.add(4 * ONEETHER).sub(gasCostTxId4).toNumber(), afterBalanceFour.toNumber(), "account_4 should refund 4 ETH");

  });

  it("fund won't be refunded, because minimal goal is reached", async () => {
    await sale.setMockedNow(1521515200);

    //Generate some token balances
    await web3.eth.sendTransaction({ from: accounts[1], to: sale.address, value: 100 * ONEETHER, gas:520000 });
    assert.equal(await web3.eth.getBalance(addressWallet).toNumber(), 100 * ONEETHER, "SaleWallet balance is 100 ETH");
    assert.equal(await wallet.deposited(accounts[1]), 100 * ONEETHER, "Deposit for 1 is 100 ETH");

    await web3.eth.sendTransaction({ from: accounts[2], to: sale.address, value: 300 * ONEETHER, gas:520000 });
    assert.equal(await web3.eth.getBalance(addressWallet).toNumber(), 400 * ONEETHER, "SaleWallet balance is 400 ETH");
    assert.equal(await wallet.deposited(accounts[2]), 300 * ONEETHER, "Deposit for 2 is 300 ETH");

    await web3.eth.sendTransaction({ from: accounts[4], to: sale.address, value: 400 * ONEETHER, gas:520000 });
    assert.equal(await web3.eth.getBalance(addressWallet).toNumber(), 800 * ONEETHER, "SaleWallet balance is 800 ETH");
    assert.equal(await wallet.deposited(accounts[4]), 400 * ONEETHER, "Deposit for 400 is 4 ETH");

    //after control time
    await sale.setMockedNow(1552651500);

    /*
    //Finalize Sale
    await sale.mockedFinalize(accounts[0]);
    */

    //Make sure further enable refunds fail
    await assertFail(async () => {
      await wallet.enableRefunds({from: accounts[0]});
    })

    //Make sure further claim refund fail
    await assertFail(async () => {
      await sale.claimRefund({from: accounts[1], gasPrice: gasPrice, gas:520000});
    })

  });

});
