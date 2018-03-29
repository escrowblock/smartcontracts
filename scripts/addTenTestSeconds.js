module.exports = function(callback) {
  web3.currentProvider.sendAsync({
    jsonrpc: '2.0',
    method: 'evm_increaseTime',
    params: [100],
    id: new Date().getSeconds()
  }, (err, resp) => {
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
