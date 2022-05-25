const truffleAssert = require('truffle-assertions');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const EIP2981RoyaltyOverride = artifacts.require("EIP2981RoyaltyOverride");
const EIP2981RoyaltyOverrideCloneable = artifacts.require("EIP2981RoyaltyOverrideCloneable");
const EIP2981RoyaltyOverrideFactory = artifacts.require("EIP2981RoyaltyOverrideFactory");
const RoyaltyRegistry = artifacts.require("RoyaltyRegistry");
const RoyaltyEngineV1 = artifacts.require("RoyaltyEngineV1")
const MockContract = artifacts.require("MockContract");

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
    indirectOwner
  ] = accounts;

  describe('Override', function() {
    var registry;
    var engine;
    var mockContract;
    var override;
    var overrideCloneable;
    var overrideFactory;
    var mockDirectOwnerContract;
    var mockIndirectlyOwnedContract;

    beforeEach(async function () {
      registry = await deployProxy(RoyaltyRegistry, {initializer: "initialize", from:owner});
      mockContract = await MockContract.new({from: another1});
      override = await EIP2981RoyaltyOverride.new({from: admin});
      overrideCloneable = await EIP2981RoyaltyOverrideCloneable.new();
      overrideFactory = await EIP2981RoyaltyOverrideFactory.new(overrideCloneable.address);

      mockIndirectlyOwnedContract = await MockContract.new({from: indirectOwner});
      mockDirectOwnerContract = await MockContract.new({from: indirectOwner});
      await mockIndirectlyOwnedContract.transferOwnership(mockDirectOwnerContract.address, { from: indirectOwner });
    });

    it('override test', async function () {
      await truffleAssert.reverts(override.setTokenRoyalties([[1, another1, 1]]), "Ownable: caller is not the owner");
      await truffleAssert.reverts(override.setDefaultRoyalty([another1, 1]), "Ownable: caller is not the owner");
    });

    it('test', async function () {
      // Check override interface
      assert.equal(await override.supportsInterface("0xc69dbd8f"), true);

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

      result = await engine.getRoyaltyView(mockIndirectlyOwnedContract.address, 1, value);
      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      await registry.setRoyaltyLookupAddress(mockIndirectlyOwnedContract.address, override.address, {from: indirectOwner});
      result = await engine.getRoyaltyView(mockIndirectlyOwnedContract.address, 1, value);
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

      await registry.setRoyaltyLookupAddress(mockIndirectlyOwnedContract.address, clone.address, {from: indirectOwner});
      result = await engine.getRoyaltyView(mockIndirectlyOwnedContract.address, 3, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[0][0], another3);
      assert.equal(result[1].length, 1);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*300/10000));
      result = await engine.getRoyaltyView(mockIndirectlyOwnedContract.address, 1, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[0][0], another4);
      assert.equal(result[1].length, 1);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*400/10000));
      result = await engine.getRoyaltyView(mockIndirectlyOwnedContract.address, 5, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[0][0], another5);
      assert.equal(result[1].length, 1);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*500/10000));
      assert.equal(2, await clone.getTokenRoyaltiesCount());

      // Test per token deletion, will go back to default
      await clone.setTokenRoyalties([[5, '0x0000000000000000000000000000000000000000', 0]], {from:admin});
      result = await engine.getRoyaltyView(mockContract.address, 5, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[0][0], another4);
      assert.equal(result[1].length, 1);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*400/10000));
      assert.equal(1, await clone.getTokenRoyaltiesCount());

      // Test per token deletion, will go back to default
      await clone.setTokenRoyalties([[5, '0x0000000000000000000000000000000000000000', 0]], {from:admin});
      result = await engine.getRoyaltyView(mockIndirectlyOwnedContract.address, 5, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[0][0], another4);
      assert.equal(result[1].length, 1);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*400/10000));
      assert.equal(1, await clone.getTokenRoyaltiesCount());
    });

  });
});
