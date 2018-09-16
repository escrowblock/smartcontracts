var MultiSigWallet = artifacts.require("MultiSigWallet");
var ESCBTokenSale = artifacts.require("ESCBTokenSale");

const multisigAddress = '0x1f0cf7afa0161b0d8e9ec076fb62bb00742d314a'
const tokenSaleAddress = '0x27a36731337cdee330d99b980b73e24f6e188618'

const ESCBCoinAddress = '0x27bf1f282ee96cdb4bb921c961fe081f397e03e4';
const networkPlaceholderAddress = '0xe37f5f16a580ec325d9076a2b2c732640a1b3356';
const safeWalletAddress = '0x61034E75eaE937992A98136d791d1d7Ab10d6e4e';

const tx = ESCBTokenSale.at(tokenSaleAddress).activateSale.request();
const data = tx.params[0].data;

console.log(`Data is ${data}`);

module.exports = function(callback) {
  return MultiSigWallet.at(multisigAddress)
                 .submitTransaction(ESCBTokenSale, 0, data, { gas: 3e5 })
                 .then(() => { console.log('tx submitted yay'); callback();})
                 .catch(e => { console.log('stopping operation'); callback();})
}
