var MultiSigWallet = artifacts.require("MultiSigWallet");
var ESCBTokenSale = artifacts.require("ESCBTokenSale");

const multisigAddress = '0x925f94B875A2289bf300f9886FD2b8ca9dD0F12c'
const tokenSaleAddress = '0x7f3bfe88fb97d275e83d9bdd93aa7a0fd0e49981'

const ESCBCoinAddress = '0x99dd050072f6655a8ee3d59fea69b4542a66ad82';
const networkPlaceholderAddress = '0x4f90503619845f4d2154a1c24325a866dbae108b';
const safeWalletAddress = '0x5f8f54eb95d6bb0c652cabcad51970053d97a22e';

const tx = ESCBTokenSale.at(tokenSaleAddress).activateSale.request();
const data = tx.params[0].data;

console.log(`Data is ${data}`);

module.exports = function(callback) {
  return MultiSigWallet.at(multisigAddress)
                 .submitTransaction(ESCBTokenSale, 0, data, { gas: 3e5 })
                 .then(() => { console.log('tx submitted yay'); callback();})
                 .catch(e => { console.log('stopping operation'); callback();})
}
