import {BigNumber} from 'bignumber.js';
BigNumber.config({ ERRORS: false });

const ESCBTokenSaleInstallationMock = artifacts.require("./mocks/ESCBTokenSaleInstallationMock.sol");
const ESCBCoinMock = artifacts.require("./mocks/ESCBCoinMock.sol");
const saleWallet = artifacts.require("saleWallet.sol");
const assertFail = require("./helpers/assertFail");

contract('Affiliate', function (accounts) {

  const ONEETHER = 1000000000000000000;
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

  it("saleWallet is active", async () => {
    assert.equal(await wallet.currentState(), "0", "SaleWallet is Active");
  });

  // =========================================================================
  it("tokens without affiliate", async () => {
    await sale.setMockedNow(1521515200);

    //Generate some token balances with bonus for 1 stage
    await web3.eth.sendTransaction({ from: accounts[1], to: sale.address, value: 2 * ONEETHER, gas: 520000 });
    assert.equal(new BigNumber(await token.balanceOf(accounts[1])).toNumber(), "24000000000000000000000", "Balance account_1 without affiliate 24000 tokens");
    assert.equal(new BigNumber(await token.balanceOf(accounts[2])).toNumber(), "0", "Balance account_2 without affiliate 0 tokens");
  });

  // =========================================================================
  it("tokens by affiliate", async () => {
    await sale.setMockedNow(1521515200);

    //Generate some token balances with referral and bonus for 1 stage
    await sale.paymentAffiliate(accounts[2], { from: accounts[1], to: sale.address, value: 2 * ONEETHER, gas:520000 });
    //console.log(new BigNumber(await token.balanceOf(accounts[1])).toNumber(), new BigNumber(await token.balanceOf(accounts[2])).toNumber());
    assert.equal(new BigNumber(await token.balanceOf(accounts[1])).toNumber(), "24480000000000000000000", "Balance account_1 with affiliate (24000 + 480) = 24480 tokens");
    assert.equal(new BigNumber(await token.balanceOf(accounts[2])).toNumber(), "480000000000000000000", "Balance account_2 with affiliate 480 tokens");
  });

});
