import {BigNumber} from 'bignumber.js';
BigNumber.config({ ERRORS: false });

// Zeppelin tests for ERC20 StandardToken.

const assertJump = require('./helpers/assertJump');
const assertGas = require('./helpers/assertGas');
const TokenReceiverMock = artifacts.require('./mocks/TokenReceiverMock.sol');
const ESCBTokenSaleTokenMock = artifacts.require('./mocks/ESCBTokenSaleTokenMock.sol');
const StandardToken = artifacts.require("MiniMeToken");

contract('StandardToken', function(accounts) {
  let token;
  const ONEETHER  = 1000000000000000000;
  beforeEach(async () => {
    const sale = await ESCBTokenSaleTokenMock.new(accounts[0], 1 * ONEETHER)
    token = StandardToken.at(await sale.token())
  })

  it("should return the correct totalSupply after construction", async function() {
    assert.equal(new BigNumber(await token.totalSupply()).toNumber(), 12000 * ONEETHER);
  })

  it("should return the correct allowance amount after approval", async function() {
    let approve = await token.approve(accounts[1], 12000 * ONEETHER);
    let allowance = await token.allowance(accounts[0], accounts[1]);

    assert.equal(allowance, 12000 * ONEETHER);
  });

  it("should return correct balances after transfer", async function() {
    let transfer = await token.transfer(accounts[1], 12000 * ONEETHER);
    let balance0 = await token.balanceOf(accounts[0]);
    assert.equal(balance0, 0);

    let balance1 = await token.balanceOf(accounts[1]);
    assert.equal(balance1, 12000 * ONEETHER);
  });

  it("should throw an error when trying to transfer more than balance", async function() {
    try {
      let transfer = await token.transfer(accounts[1], 12001 * ONEETHER);
    } catch(error) {
      return assertJump(error);
    }
    assert.fail('should have thrown before');
  });

  it("should return correct balances after transfering from another account", async function() {
    let approve = await token.approve(accounts[1], 12000 * ONEETHER);
    let transferFrom = await token.transferFrom(accounts[0], accounts[2], 12000 * ONEETHER, {from: accounts[1]});

    let balance0 = await token.balanceOf(accounts[0]);
    assert.equal(balance0, 0);

    let balance1 = await token.balanceOf(accounts[2]);
    assert.equal(balance1, 12000 * ONEETHER);

    let balance2 = await token.balanceOf(accounts[1]);
    assert.equal(balance2, 0);
  });

  it("should throw an error when trying to transfer more than allowed", async function() {
    let approve = await token.approve(accounts[1], 99);
    try {
      let transfer = await token.transferFrom(accounts[1], accounts[2], 12000 * ONEETHER, {from: accounts[1]});
    } catch (error) {
      return assertJump(error);
    }
    assert.fail('should have thrown before');
  });

  it("should approve and call", async function() {
    let receiver = await TokenReceiverMock.new()
    await token.approveAndCall(receiver.address, 15, '0xbeef')

    assert.equal(await receiver.tokenBalance(), 15, 'Should have transfered tokens under the hood')
    assert.equal(await receiver.extraData(), '0xbeef', 'Should have correct extra data')
  })

  it("approve and call should throw when transferring more than balance", async function() {
    let receiver = await TokenReceiverMock.new()
    try {
      let approveAndCall = await token.approveAndCall(receiver.address, 12050 * ONEETHER, '0xbeef')
    } catch (error) {
      return assertJump(error);
    }
    assert.fail('should have thrown before');
  })
});
