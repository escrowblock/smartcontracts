const recipient = process.env.recipient || '0x694847098248bb900ee3ec9b6a19e97cc7876bfb';
const amount = process.env.amount || 2e18;

module.exports = function(callback) {
  console.log(web3.eth.accounts[0], web3.eth.accounts[1], recipient, amount);
  web3.eth.sendTransaction({
    from: web3.eth.accounts[0],
    to: '0x694847098248bb900ee3ec9b6a19e97cc7876bfb', // recipient
    value: amount, // wei
    gas: 100000,
    data: '0x0'
  }, (err, resp) => {
    console.log(err, resp);
    if (!err) {
      web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_mine',
        params: [],
        id: new Date().getSeconds()
      })
    }
  });
  return true;
}
