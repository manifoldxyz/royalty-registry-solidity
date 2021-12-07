const truffleAssert = require('truffle-assertions');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const EIP2981RoyaltyOverride = artifacts.require("EIP2981RoyaltyOverride");
const EIP2981RoyaltyOverrideCloneable = artifacts.require("EIP2981RoyaltyOverrideCloneable");
const EIP2981RoyaltyOverrideFactory = artifacts.require("EIP2981RoyaltyOverrideFactory");
const MultiContractRoyaltyOverrideArtBlocks = artifacts.require("MultiContractRoyaltyOverrideArtBlocks");
const RoyaltyRegistry = artifacts.require("RoyaltyRegistry");
const RoyaltyEngineV1 = artifacts.require("RoyaltyEngineV1")
const MockContract = artifacts.require("MockContract");
const MockArtBlocks = artifacts.require("MockArtBlocks");

contract('Registry', function ([...accounts]) {
  const [
    owner,
    admin,
    another1,
    another2,
    another3,
    another4,
    another5,
    another6,
  ] = accounts;

  describe('Override', function() {
    var registry;
    var engine;
    var mockContract;
    var override;
    var overrideCloneable;
    var overrideFactory;
    var mockArtBlocks;

    beforeEach(async function () {
      registry = await deployProxy(RoyaltyRegistry, {initializer: "initialize", from:owner});
      mockContract = await MockContract.new({from: another1});
      override = await EIP2981RoyaltyOverride.new({from: admin});
      overrideCloneable = await EIP2981RoyaltyOverrideCloneable.new();
      overrideFactory = await EIP2981RoyaltyOverrideFactory.new(overrideCloneable.address);
      multiContractOverrideArtBlocks = await MultiContractRoyaltyOverrideArtBlocks.new({from: admin});
      mockArtBlocks = await MockArtBlocks.new({from: another1});
    });

    it('override test', async function () {
      await truffleAssert.reverts(override.setTokenRoyalties([[1, another1, 1]]), "Ownable: caller is not the owner");
      await truffleAssert.reverts(override.setDefaultRoyalty([another1, 1]), "Ownable: caller is not the owner");
    });

    it('test', async function () {
      // Check override interface
      assert.equal(await override.supportsInterface("0xc69dbd8f"), true);
      assert.equal(await override.supportsInterface("0xffffffff"), false);

      await truffleAssert.reverts(override.setTokenRoyalties([[1, another1, 10000]], {from:admin}), "Invalid bps");
      await truffleAssert.reverts(override.setDefaultRoyalty([another1, 10000], {from:admin}), "Invalid bps");

      engine = await deployProxy(RoyaltyEngineV1, [registry.address], {initializer: "initialize", from:owner});
      let value = 1000;

      let result = await override.royaltyInfo(1, value);
      assert.equal(result[0], "0x0000000000000000000000000000000000000000");
      assert.equal(result[1], 0);

      await override.setTokenRoyalties([[1, another1, 100]], {from:admin});
      result = await override.royaltyInfo(1, value);
      assert.equal(result[0], another1);
      assert.equal(result[1], value*100/10000);

      await override.setDefaultRoyalty([another2, 200], {from:admin});
      result = await override.royaltyInfo(1, value);
      assert.equal(result[0], another1);
      assert.equal(result[1], value*100/10000);
      result = await override.royaltyInfo(2, value);
      assert.equal(result[0], another2);
      assert.equal(result[1], value*200/10000);

      result = await engine.getRoyaltyView(mockContract.address, 1, value);
      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      await registry.setRoyaltyLookupAddress(mockContract.address, override.address, {from: another1});
      result = await engine.getRoyaltyView(mockContract.address, 1, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[0][0], another1);
      assert.equal(result[1].length, 1);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*100/10000));

      // Creating override clone
      var tx = await overrideFactory.createOverride({from:admin});
      console.log("Create override gas used: %s", tx.receipt.gasUsed);
      var clone = await EIP2981RoyaltyOverride.at(tx.logs[0].args.newEIP2981RoyaltyOverride);
      await clone.setTokenRoyalties([[3, another3, 300], [5, another5, 500]], {from:admin});
      result = await clone.royaltyInfo(3, value);
      assert.equal(result[0], another3);
      assert.equal(result[1], value*300/10000);
      result = await clone.royaltyInfo(5, value);
      assert.equal(result[0], another5);
      assert.equal(result[1], value*500/10000);

      await clone.setDefaultRoyalty([another4, 400], {from:admin});
      result = await clone.royaltyInfo(3, value);
      assert.equal(result[0], another3);
      assert.equal(result[1], value*300/10000);
      result = await clone.royaltyInfo(1, value);
      assert.equal(result[0], another4);
      assert.equal(result[1], value*400/10000);

      await registry.setRoyaltyLookupAddress(mockContract.address, clone.address, {from: another1});
      result = await engine.getRoyaltyView(mockContract.address, 3, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[0][0], another3);
      assert.equal(result[1].length, 1);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*300/10000));
      result = await engine.getRoyaltyView(mockContract.address, 1, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[0][0], another4);
      assert.equal(result[1].length, 1);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*400/10000));
      result = await engine.getRoyaltyView(mockContract.address, 5, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[0][0], another5);
      assert.equal(result[1].length, 1);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*500/10000));
      assert.equal(2, await clone.getTokenRoyaltiesCount());

      // Test per token deletion, will go back to default
      await clone.setTokenRoyalties([[5, '0x0000000000000000000000000000000000000000', 0]], {from:admin})
      result = await engine.getRoyaltyView(mockContract.address, 5, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[0][0], another4);
      assert.equal(result[1].length, 1);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*400/10000));
      assert.equal(1, await clone.getTokenRoyaltiesCount())
    });


    it('test multi-contract artblocks', async function () {
      // Check override interface
      assert.equal(await multiContractOverrideArtBlocks.supportsInterface("0x9ca7dc7a"), true);
      assert.equal(await multiContractOverrideArtBlocks.supportsInterface("0xffffffff"), false);

      // expect revert when asking for royalties of EOA, directly from override contract
      await truffleAssert.reverts(multiContractOverrideArtBlocks.getRoyalties(another2, 0, {from:another1}), "revert");

      engine = await deployProxy(RoyaltyEngineV1, [registry.address], {initializer: "initialize", from:owner});
      let value = 1000;

      // expect empty responses when asking for royalties of mockArtBlocks w/o override
      let result = await engine.getRoyaltyView(mockArtBlocks.address, 0, value, {from:another1});
      assert.equal(result["recipients"].length, 0);
      assert.equal(result["amounts"].length, 0);

      // set mockArtBlocks override to be multiContractOverrideArtBlocks
      await registry.setRoyaltyLookupAddress(mockArtBlocks.address, multiContractOverrideArtBlocks.address, {from:another1});

      // expect override to return mockArtBlocks default royalty results
      result = await engine.getRoyaltyView(mockArtBlocks.address, 0, value, {from:another1});
      assert.deepEqual(result[0],["0x0000000000000000000000000000000000000000", another1]);
      assert.deepEqual(result[1], [web3.utils.toBN(value*4/100), web3.utils.toBN(value*1/100)]);

      // expect override to return mockArtBlocks default royalty results when someone else calls
      result = await engine.getRoyaltyView(mockArtBlocks.address, 0, value, {from:another2});
      assert.deepEqual(result[0],["0x0000000000000000000000000000000000000000", another1]);
      assert.deepEqual(result[1], [web3.utils.toBN(value*4/100), web3.utils.toBN(value*1/100)]);

      // expect to return mockArtBlocks default royalty results (in bps) when calling override contract directly
      result = await multiContractOverrideArtBlocks.getRoyalties(mockArtBlocks.address, 0, {from:another1});
      assert.deepEqual(result[0],["0x0000000000000000000000000000000000000000", another1]);
      assert.deepEqual(result[1], [web3.utils.toBN(10000*4/100), web3.utils.toBN(10000*1/100)]);

      // expect revert when asking for royalties of non-artblocks contract
      await registry.setRoyaltyLookupAddress(mockContract.address, multiContractOverrideArtBlocks.address, {from:another1});
      await truffleAssert.reverts(engine.getRoyaltyView(mockContract.address, 0, value, {from:another1}), "revert");
    });

  });
});