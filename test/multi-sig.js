const { expect } = require("chai");
const { ethers, web3 } = require("hardhat");

require("@nomiclabs/hardhat-web3");

describe("MultiSig", function () {
  it("It should create a tx and confirm once.", async function () {
    // Get all Hardhat accounts and use the first 3 as the owners of the multi-sig
    const deployerWallets = await ethers.getSigners()
    // console.log(deployerWallets[0])
    const MultiSig = await ethers.getContractFactory("MultiSig");
    const multiSig = await MultiSig.deploy([deployerWallets[0].address, deployerWallets[1].address, deployerWallets[2].address], 1);
    await multiSig.deployed();
    console.log(ethers.getDefaultProvider())

    // Create tx for 1 ETH
    const createTx = await multiSig.submitTransaction("0x90F79bf6EB2c4f870365E785982E1f101E93b906", ethers.utils.parseEther("1"), 0x00);
    // wait until the transaction is mined
    await createTx.wait();

    // Have deployer also vote since he is a member
    const confirm1 = await multiSig.confirmTransaction(1);
    await confirm1.wait();

    //const confirm2 = await multiSig.confirmTransaction(1);
    //await confirm2.wait();
    const result = await multiSig.getTransaction(1);
    expect(parseInt(result.numConfirmations)).to.equal(1);
    // console.log(result)

    // Send funds to the wallet which will be paid out upon execution of the transaction. 
    await deployerWallets[0].sendTransaction({
      to: multiSig.address,
      value: ethers.utils.parseEther("1")
    })

    // Execute the transaction
    const exec = await multiSig.executeTransaction(1);
    await exec.wait();
    expect(await web3.eth.getBalance("0x90F79bf6EB2c4f870365E785982E1f101E93b906")).to.equal(ethers.utils.parseEther("10001"));
  });
});
