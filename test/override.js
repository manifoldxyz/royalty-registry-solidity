const truffleAssert = require('truffle-assertions');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const EIP2981RoyaltyOverride = artifacts.require("EIP2981RoyaltyOverride");
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
  ] = accounts;

  describe('Override', function() {
    var registry;
    var engine;
    var mockContract;
    var override;

    beforeEach(async function () {
      registry = await deployProxy(RoyaltyRegistry, {initializer: "initialize", from:owner});
      mockContract = await MockContract.new({from: another1});
      override = await EIP2981RoyaltyOverride.new({from: admin});
    });

    it('override test', async function () {
      await truffleAssert.reverts(override.setTokenRoyalty(1, another1, 1), "Ownable: caller is not the owner");
      await truffleAssert.reverts(override.setDefaultRoyalty(another1, 1), "Ownable: caller is not the owner");
    });

    it('test', async function () {
      engine = await deployProxy(RoyaltyEngineV1, [registry.address], {initializer: "initialize", from:owner});
      let value = 1000;

      let result = await override.royaltyInfo(1, value);
      assert.equal(result[0], "0x0000000000000000000000000000000000000000");
      assert.equal(result[1], 0);

      await override.setTokenRoyalty(1, another1, 100, {from:admin});
      result = await override.royaltyInfo(1, value);
      assert.equal(result[0], another1);
      assert.equal(result[1], value*100/10000);

      await override.setDefaultRoyalty(another2, 200, {from:admin});
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
    });

  });
});