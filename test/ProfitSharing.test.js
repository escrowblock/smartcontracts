import {BigNumber} from 'bignumber.js';
BigNumber.config({ ERRORS: false });

const ESCBTokenSaleInstallationMock = artifacts.require("./mocks/ESCBTokenSaleInstallationMock.sol");
const ESCBCoinMock = artifacts.require("./mocks/ESCBCoinMock.sol");
const saleWallet = artifacts.require("saleWallet.sol");
const assertFail = require("./helpers/assertFail");

contract('ProfitSharing', function (accounts) {

  const ONEETHER  = 1000000000000000000;
  const YEAR = (24*60*60) * 366;
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
  it("profit sharing", async () => {
    await sale.setMockedNow(1521515200);

    // Generate some token balances for ETH
    await web3.eth.sendTransaction({ from: accounts[1], to: sale.address, value: 10 * ONEETHER, gas:520000 });
    assert.equal(await web3.eth.getBalance(addressWallet).toNumber(), 10 * ONEETHER, "SaleWallet balance is 1 ETH");
    assert.equal(await wallet.deposited(accounts[1]), 10 * ONEETHER, "Deposit for account 1 is 1 ETH");

    await web3.eth.sendTransaction({ from: accounts[2], to: sale.address, value: 30 * ONEETHER, gas:520000 });
    assert.equal(await web3.eth.getBalance(addressWallet).toNumber(), 40 * ONEETHER, "SaleWallet balance is 4 ETH");
    assert.equal(await wallet.deposited(accounts[2]), 30 * ONEETHER, "Deposit for account 2 is 3 ETH");

    await web3.eth.sendTransaction({ from: accounts[4], to: sale.address, value: 40 * ONEETHER, gas:520000 });
    assert.equal(await web3.eth.getBalance(addressWallet).toNumber(), 80 * ONEETHER, "SaleWallet balance is 8 ETH");
    assert.equal(await wallet.deposited(accounts[4]), 40 * ONEETHER, "Deposit for account 4 is 4 ETH");

    //Generate some token balances for cards
    await sale.issueWithExternalFoundation(accounts[5], 10 * ONEETHER, 'How does evaluate profit by cards?');

    //1st allocation for ESCB
    await sale.allocationForESCBbyStage();

    //Check ESCB foundation account
    assert.equal(new BigNumber(await token.balanceOf(accounts[0])).toNumber(), 490000 * ONEETHER, "Balance for account ESCB dev is 490 000 tokens");

    //Finalize Sale
    await sale.mockedFinalize(accounts[0]);

    //Make a deposit
    await token.depositDividend({from: accounts[0], value: 1 * ONEETHER});

    //Claim dividend
    var beforeBalanceOne = new BigNumber(await web3.eth.getBalance(accounts[1]));
    var beforeBalanceTwo = new BigNumber(await web3.eth.getBalance(accounts[2]));
    var beforeBalanceFour = new BigNumber(await web3.eth.getBalance(accounts[4]));
    var beforeBalanceFive = new BigNumber(await web3.eth.getBalance(accounts[5]));

    var txId1 = await token.claimDividend(0, {from: accounts[1], gasPrice: gasPrice});
    var txId2 = await token.claimDividend(0, {from: accounts[2], gasPrice: gasPrice});
    var txId4 = await token.claimDividend(0, {from: accounts[4], gasPrice: gasPrice});
    var txId5 = await token.claimDividend(0, {from: accounts[5], gasPrice: gasPrice});
    var afterBalanceOne = new BigNumber(await web3.eth.getBalance(accounts[1]));
    var afterBalanceTwo = new BigNumber(await web3.eth.getBalance(accounts[2]));
    var afterBalanceFour = new BigNumber(await web3.eth.getBalance(accounts[4]));
    var afterBalanceFive = new BigNumber(await web3.eth.getBalance(accounts[5]));
    var gasCostTxId1 = txId1.receipt.gasUsed * gasPrice;
    var gasCostTxId2 = txId2.receipt.gasUsed * gasPrice;
    var gasCostTxId4 = txId4.receipt.gasUsed * gasPrice;
    var gasCostTxId5 = txId5.receipt.gasUsed * gasPrice;

    assert.equal(beforeBalanceOne.add(new BigNumber(76530612244897959)).sub(gasCostTxId1).toNumber(), afterBalanceOne.toNumber(), "account_1 should claim ~0.076 of dividend");
    assert.equal(beforeBalanceTwo.add(new BigNumber(229591836734693877)).sub(gasCostTxId2).toNumber(), afterBalanceTwo.toNumber(), "account_2 should claim ~0.229 of dividend");
    assert.equal(beforeBalanceFour.add(new BigNumber(306122448979591836)).sub(gasCostTxId4).toNumber(), afterBalanceFour.toNumber(), "account_4 should claim ~0.30 of dividend");
    assert.equal(beforeBalanceFive.add(new BigNumber(75255102040816326)).sub(gasCostTxId5).toNumber(), afterBalanceFive.toNumber(), "account_5 should claim ~0.076 of dividend");

    //Make sure further claims on this dividend fail
    await assertFail(async () => {
      await token.claimDividend(0, {from: accounts[1], gasPrice: gasPrice});
    })

    await assertFail(async () => {
      await token.claimDividend(0, {from: accounts[2], gasPrice: gasPrice});
    })

    //Make sure zero balances give no value
    var beforeBalanceThree = await web3.eth.getBalance(accounts[3]);
    var txId3 = await token.claimDividend(0, {from: accounts[3], gasPrice: gasPrice});
    var afterBalanceThree = await web3.eth.getBalance(accounts[3]);
    var gasCostTxId3 = txId3.receipt.gasUsed * gasPrice;

    assert.equal(beforeBalanceThree.sub(gasCostTxId1).toNumber(), afterBalanceThree.toNumber(), "account_3 should have no claim");

    //Recycle remainder of dividend 0
    await token.setMockedNow(1521515200 + YEAR);
    await token.recycleDividend(0, {from: accounts[0], gas:520000});

    //Check everyone can claim recycled dividend
    beforeBalanceOne = await web3.eth.getBalance(accounts[1]);
    beforeBalanceTwo = await web3.eth.getBalance(accounts[2]);
    beforeBalanceFour = await web3.eth.getBalance(accounts[4]);

    var balanceTokenOne = await token.balanceOf(accounts[1]);
    var balanceTokenTwo = await token.balanceOf(accounts[2]);
    var balanceTokenFour = await token.balanceOf(accounts[4]);

    txId1 = await token.claimDividendAll({from: accounts[1], gasPrice: gasPrice});
    txId2 = await token.claimDividendAll({from: accounts[2], gasPrice: gasPrice});
    txId4 = await token.claimDividendAll({from: accounts[4], gasPrice: gasPrice});

    afterBalanceOne = await web3.eth.getBalance(accounts[1]);
    afterBalanceTwo = await web3.eth.getBalance(accounts[2]);
    afterBalanceFour = await web3.eth.getBalance(accounts[4]);
    afterBalanceESCB = await web3.eth.getBalance(accounts[0]);

    gasCostTxId1 = txId1.receipt.gasUsed * gasPrice;
    gasCostTxId2 = txId2.receipt.gasUsed * gasPrice;
    gasCostTxId4 = txId3.receipt.gasUsed * gasPrice;

    var totalSupply = await token.totalSupply();

    //Balances for recycled dividend 1 are 1, 3, 4, total = 1570900.909090909090909089 * ONEETHER,
    //recycled dividend is 312500000000000003 weis
    assert.equal(beforeBalanceOne.add(new BigNumber((balanceTokenOne / totalSupply) * (312500000000000003))).sub(gasCostTxId1).toNumber(), afterBalanceOne.toNumber(), "account_1 should claim dividend");
    assert.equal(beforeBalanceTwo.add(new BigNumber((balanceTokenTwo / totalSupply) * (312500000000000003))).sub(gasCostTxId2).toNumber(), afterBalanceTwo.toNumber(), "account_2 should claim dividend");
    assert.equal(beforeBalanceFour.add(new BigNumber((balanceTokenFour / totalSupply) * (312500000000000003))).sub(gasCostTxId4).toNumber(), afterBalanceFour.toNumber(), "account_4 should claim dividend");

    //Check ESCB profit
    var beforeBalanceESCB = await web3.eth.getBalance(accounts[0]);
    var txId0 = await token.claimDividendAll({from: accounts[0], gasPrice: gasPrice});
    var gasCostTxId0 = txId0.receipt.gasUsed * gasPrice;
    var afterBalanceESCB = await web3.eth.getBalance(accounts[0]);
    var balanceTokenESCB = await token.balanceOf(accounts[0]);
    assert.equal(beforeBalanceESCB.add(new BigNumber((balanceTokenESCB / totalSupply) * (312500000000000003))).sub(gasCostTxId0).toNumber(), afterBalanceESCB.toNumber(), "account_0 ESCB should claim dividend");
  });

});
