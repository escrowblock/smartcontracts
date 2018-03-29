var MultiSigWallet = artifacts.require("MultiSigWallet");
var ESCBTokenSale = artifacts.require("ESCBTokenSale");

const multisigAddress = '0x753dC527f5E20B1Ad871be84F1A8afe915793D9a'
const tokenSaleAddress = '0xdeb92871b374ea477a6de45fbbc8db3181db7a55'

const ESCBCoinAddress = '0x35a703c21310cdc73600e835dce285b9badbadee';
const networkPlaceholderAddress = '0x6ec099f6cda14752b5a8bf613c9eed35801025f7';
const safeWalletAddress = '0x75b687e4a62c975bf2de1c40e515eeb112f79513';

const tx = ESCBTokenSale.at(tokenSaleAddress).setESCBCoin.request(ESCBCoinAddress, networkPlaceholderAddress, safeWalletAddress);
const data = tx.params[0].data;

console.log(`Data is ${data}`);

module.exports = function(callback) {
  return MultiSigWallet.at(multisigAddress)
                 .submitTransaction(ESCBTokenSale, 0, data, { gas: 3e5 })
                 .then(() => { console.log('tx submitted yay'); callback();})
                 .catch(e => { console.log('stopping operation'); callback();})
}
