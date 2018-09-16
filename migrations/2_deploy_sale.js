var ESCBTokenSale = artifacts.require("ESCBTokenSale");
var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
var ESCBCoinPlaceholder = artifacts.require("ESCBCoinPlaceholder");
var ESCBCoin = artifacts.require("ESCBCoin");
var SaleWallet = artifacts.require("SaleWallet");

module.exports = function(deployer, network, accounts) {
  let initialTime    = 1537185600; // when with Airdrop will be started 1537185600 09/17/2018 @ 12:00am (UTC)
  let controlTime    = 1554206400;
  const price        = 5000; // 1ETH = 500 USD and 1 token is 0.1 USD
  const minGoal      = 80000000000000000000; //80 ETH in weis
  const goal         = 20000000000000000000000; //20 000 ETH in weis
  let ESCBMs         = '0x1f0cf7afa0161b0d8e9ec076fb62bb00742d314a';

  if(network == "testganache") {
    initialTime = Math.round(new Date().getTime()/1000) + 60; // 60 seconds before start
    controlTime = Math.round(new Date().getTime()/1000) + 240*60; // 120 minutes before test refunding
    ESCBMs      = '0x2e47e6e0bf4fafd4ea361a8a3d2f88f68624624c';
  }

  deployer.deploy(MiniMeTokenFactory);
  deployer.deploy(
    ESCBTokenSale,
    initialTime,
    controlTime,
    ESCBMs,
    price)
    .then(() => {
      return MiniMeTokenFactory.deployed()
        .then(f => {
          factory = f;
          return ESCBTokenSale.deployed();
        })
        .then(s => {
          sale = s;
          return ESCBCoin.new(factory.address);
        }).then(a => {
          ESCBCoin = a;
          console.log('ESCBCoin:', ESCBCoin.address);
          return ESCBCoin.changeController(sale.address);
        })
        .then(() => {
          return ESCBCoin.setCanCreateGrants(sale.address, true);
        })
        .then(() => {
          return ESCBCoin.changeVestingWhitelister(ESCBMs);
        })
        .then(() => {
          return ESCBCoinPlaceholder.new(sale.address, ESCBCoin.address);
        })
        .then(n => {
          networkPlaceholder = n;
          console.log('Placeholder:', networkPlaceholder.address);
          return SaleWallet.new(ESCBMs, sale.address);
        })
        .then(wallet => {
          console.log('Wallet:', wallet.address);
          console.log("setESCBCoin as: " + ESCBCoin.address + " - " + networkPlaceholder.address + " - " + wallet.address + " - " + minGoal + " - " + goal);
          return sale.setESCBCoin(ESCBCoin.address, networkPlaceholder.address, wallet.address, minGoal, goal);
        })
    })
};
