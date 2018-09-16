require('babel-register');
require('babel-polyfill');

var HDWalletProvider = require('truffle-hdwallet-provider');

const mnemonic = process.env.TEST_MNEMONIC || 'wallet wallet wallet wallet wallet wallet wallet wallet wallet wallet wallet wallet';
const apiKey = process.env.TEST_APIKEY || 000000000;
const kovanProvider = new HDWalletProvider(mnemonic, 'https://kovan.infura.io/' + apiKey);

const mnemonicMain = process.env.MNEMONIC || 'wallet wallet wallet wallet wallet wallet wallet wallet wallet wallet wallet wallet';
const apiKeyMain = process.env.APIKEY || 000000000;
const mainProvider = new HDWalletProvider(mnemonicMain, 'https://mainnet.infura.io/' + apiKeyMain);

module.exports = {
  networks: {
    development: {
      network_id: "*",
      host: 'localhost',
      port: 8545,
      gas: 6000000,
      from: '0x25f5cabf186a4a05d66adab5b8214b8b5e5a5cb7',
    },
    private: {
      network_id: "*",
      host: 'localhost',
      port: 8545,
      gas: 4999999,
      from: '0x89d0a9ad9658b487f3a7948bea5443dbe858fb51',
    },
    test: {
      provider: require('ethereumjs-testrpc').provider({ gasLimit: 100000000000 }),
      gas: 10000000000,
      from: '0x89d0a9ad9658b487f3a7948bea5443dbe858fb51',
      network_id: "54"
    },
    testganache: {
      //provider: require("ganache-cli").provider({ gasLimit: 100000000000, from: '0x2e47e6e0bf4fafd4ea361a8a3d2f88f68624624c' }),
      gas: 10000000000,
      from: '0x2e47e6e0bf4fafd4ea361a8a3d2f88f68624624c',
      network_id: "*",
      host: 'localhost',
      port: 8545
    },
    mainnet: {
      network_id: 1,
      provider: mainProvider,
      gas: 5999999,
      gasPrice: 7000000000,
      nonce: 43
    },
    kovan: {
      network_id: 42,
      provider: kovanProvider,
      gas: 4999999
    },
  }
}
