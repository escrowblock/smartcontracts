module.exports = {
    norpc: true,
    testCommand: 'node --max-old-space-size=2047 ../node_modules/.bin/truffle test --network coverage',
    skipFiles: ['lifecycle/Migrations.sol']
}
