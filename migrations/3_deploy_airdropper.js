var ESCBAirdropper = artifacts.require("ESCBAirdropper");

module.exports = function(deployer, network, accounts) {
  const amount       = 100;
  let ESCBMs         = '0x1f0cf7afa0161b0d8e9ec076fb62bb00742d314a';
  let ESCBCoin       = '0x5e365a320779acc2c72f5dcd2ba8a81e4a34569f';

  if(network == "testganache") {
    ESCBMs      = '0x2e47e6e0bf4fafd4ea361a8a3d2f88f68624624c';
    ESCBCoin    = '0x1f0cf7afa0161b0d8e9ec076fb62bb00742d314a';
  }

  deployer.deploy(
    ESCBAirdropper,
    amount,
    ESCBCoin)
    .then(() => {
      return ESCBAirdropper.deployed()
        .then((a) => {
          return a.setAirdropAgent(ESCBMs, true);
        })
    })
};
