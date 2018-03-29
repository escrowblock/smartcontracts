var MultiSigWallet = artifacts.require("MultiSigWallet");
var ESCBTokenSale = artifacts.require("ESCBTokenSale");

const multisigAddress  = '0x2e47e6e0bf4fafd4ea361a8a3d2f88f68624624c';
const tokenSaleAddress = '0x959c65542d1694c7f0078b66b118c305827f1e4d';

module.exports = function(callback) {
  return ESCBTokenSale.at(tokenSaleAddress).activateSale({from: multisigAddress});
}
