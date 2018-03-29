import {BigNumber} from 'bignumber.js';
BigNumber.config({ ERRORS: false });

const ESCBTokenSaleInstallationMock = artifacts.require("./mocks/ESCBTokenSaleInstallationMock.sol");
const ESCBCoinMock = artifacts.require("./mocks/ESCBCoinMock.sol");
const saleWallet = artifacts.require("saleWallet.sol");
const assertFail = require("./helpers/assertFail");

contract('Stages', function (accounts) {

  const ONEETHER = 1000000000000000000;
  const gasPrice = 0;

  let sale, addressToken, token, addressWallet, wallet;
  beforeEach(async () => {
    sale = await ESCBTokenSaleInstallationMock.new();
    addressToken = await sale.token();
    token = ESCBCoinMock.at(addressToken);
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

  it("saleWallet is active", async () => {
    assert.equal(await wallet.currentState(), "0", "SaleWallet is Active");
  });

  // =========================================================================
  it("bonus for 1 stage", async () => {
    await sale.setMockedNow(1521515200);

    //Generate some token balances with bonus for 1 stage
    await web3.eth.sendTransaction({ from: accounts[1], to: sale.address, value: 2 * ONEETHER, gas: 520000 });
    assert.equal(new BigNumber(await token.balanceOf(accounts[1])).toNumber(), "24000000000000000000000", "Balance account_1 with bonus 24000 tokens");
  });

  it("bonus for 2 stage", async () => {
    await sale.setMockedNow(1521515200);

    //Generate some token balances with bonus for 1 stage
    await web3.eth.sendTransaction({ from: accounts[1], to: sale.address, value: 50 * ONEETHER, gas: 520000 });
    assert.equal(new BigNumber(await token.balanceOf(accounts[1])).toNumber(), "600000000000000000000000", "Balance account_1 with bonus 600000 tokens");

    //Generate some token balances with bonus for 2 stage
    await web3.eth.sendTransaction({ from: accounts[1], to: sale.address, value: 5 * ONEETHER, gas: 520000 });
    assert.equal(new BigNumber(await token.balanceOf(accounts[1])).toNumber(), "659000000000000000000000", "Balance account_1 with bonus 659000 tokens");
  });

  it("allocation for ESCB", async () => {
    await sale.setMockedNow(1521515200);

    //Generate some token balances with bonus for 1 stage
    await web3.eth.sendTransaction({ from: accounts[1], to: sale.address, value: 35 * ONEETHER, gas: 520000 });
    assert.equal(new BigNumber(await token.balanceOf(accounts[1])).toNumber(), "420000000000000000000000", "Balance account_1 (1 stage 35 ETH) with bonus 420000 tokens");

    //Generate some token balances with bonus for 1 stage
    await web3.eth.sendTransaction({ from: accounts[1], to: sale.address, value: 10 * ONEETHER, gas: 520000 });
    assert.equal(new BigNumber(await token.balanceOf(accounts[1])).toNumber(), "540000000000000000000000", "Balance account_1 (1 stage 10 ETH) with bonus 540000 tokens");

    assert.equal(new BigNumber(await sale.currentStage()).toNumber(), "1", "Current stage 1");
    assert.equal(new BigNumber(await sale.allocatedStage()).toNumber(), "1", "Current allocated stage 1");

    //Generate some token balances with bonus for 2 stage
    await web3.eth.sendTransaction({ from: accounts[1], to: sale.address, value: 10 * ONEETHER, gas: 520000 });
    assert.equal(new BigNumber(await token.balanceOf(accounts[1])).toNumber(), "658000000000000000000000", "Balance account_1 (2 stage 10 ETH) with bonus 658 000 tokens");

    assert.equal(new BigNumber(await sale.currentStage()).toNumber(), "2", "After purchasing 2 stage - Current stage 2");
    assert.equal(new BigNumber(await sale.allocatedStage()).toNumber(), "1", "Current allocated stage 1");

    assert.equal(new BigNumber(await token.totalSupply()).toNumber(), "658000000000000000000000", "Total collected 658 000");

    assert.equal(new BigNumber(await sale.usedTotalSupply()).toNumber(), "0", "UsedTotalSupply before 1 allocation 0");

    //1st allocation for ESCB
    await sale.allocationForESCBbyStage();

    assert.equal(new BigNumber(await sale.allocatedStage()).toNumber(), "2", "After the allocation current allocated stage 2");

    assert.equal(new BigNumber(await token.balanceOf(accounts[0])).toNumber(), "299090909090909080000000", "Balance ESCB after 2 stage ~ 299 090 tokens");

    //Generate some token balances with bonus for 2 stage
    await web3.eth.sendTransaction({ from: accounts[1], to: sale.address, value: 100 * ONEETHER, gas: 520000 });
    assert.equal(new BigNumber(await token.balanceOf(accounts[1])).toNumber(), "1838000000000000000000000", "Balance account_1 (2 stage 100 ETH) with bonus 1 838 000 tokens");

    //Generate some token balances with bonus for 3 stage
    await web3.eth.sendTransaction({ from: accounts[1], to: sale.address, value: 10 * ONEETHER, gas: 520000 });
    assert.equal(new BigNumber(await token.balanceOf(accounts[1])).toNumber(), "1954000000000000000000000", "Balance account_1 (3 stage 10 ETH) with bonus 1 954 000 tokens");

    assert.equal(new BigNumber(await sale.allocatedStage()).toNumber(), "2", "Current allocated stage 2 before allocation for ESCB");

    assert.equal(new BigNumber(await token.totalSupply()).toNumber(), "2253090909090909000000000", "Total collected ~ 2 253 090");

    assert.equal(new BigNumber(await sale.usedTotalSupply()).toNumber(), "658000000000000000000000", "UsedTotalSupply before 1 allocation 658 000");

    //2nd allocation for ESCB
    await sale.allocationForESCBbyStage();

    assert.equal(new BigNumber(await sale.currentStage()).toNumber(), "3", "After purchasing 3 stage - Current stage 3");
    assert.equal(new BigNumber(await sale.allocatedStage()).toNumber(), "3", "Current allocated stage 3 after allocation for ESCB");

    assert.equal(new BigNumber(await token.balanceOf(accounts[0])).toNumber(), "1024132231404958700000000", "Balance ESCB ~1 024 132 tokens when totalSuplly on 2 stage is");
  });

});
