# Multi Sig 'Wallet' Smart Contract

In this project on can deploy a multiple signature wallet. Meaning, in order to make transactions, the threshold of signatures required must be reached. All specifications of the type of wallet can be specified in this contract. Enabling usage with multiple signer scenarios. 

A test has been created in the 'test' folder. Run this locally to test the contract. 

If you want to deploy to mainnet, change the network variable in the hardhat.config file to mainnet, or whatever chain from the options specified.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat console --network localhost
node scripts/create-box.js
node scripts/deploy.js
npx hardhat generate
npx hardhat account
```

Useful Hardhat console commands:
```shell
const Box = await ethers.getContractFactory("Box")
const box = await Box.attach("paste-contract-address-here")
(await box.retrieve()).toString()
await box.store(5)
```