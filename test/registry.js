const truffleAssert = require('truffle-assertions');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Registry = artifacts.require("Registry");
const MockContract = artifacts.require("MockContract");
const MockManifold = artifacts.require("MockManifold");
const MockFoundation = artifacts.require("MockFoundation");
const MockRaribleV1 = artifacts.require("MockRaribleV1");
const MockRaribleV2 = artifacts.require("MockRaribleV2");
const MockEIP2981 = artifacts.require("MockEIP2981");

contract('Registry', function ([...accounts]) {
  const [
    owner,
    another1,
    another2,
    another3,
    another4,
    another5,
    another6,
  ] = accounts;

  describe('Registry', function() {
    var registry;
    var mockContract;
    var mockManifold;
    var mockFoundation;
    var mockRaribleV1;
    var mockRaribleV2;
    var mockEIP2981;

    beforeEach(async function () {
      registry = await deployProxy(Registry, {initializer: "initialize", from:owner});
      mockContract = await MockContract.new({from: another1});
      mockManifold = await MockManifold.new({from: another2});
      mockFoundation = await MockFoundation.new({from: another3});
      mockRaribleV1 = await MockRaribleV1.new({from: another4});
      mockRaribleV2 = await MockRaribleV2.new({from: another5});
      mockEIP2981 = await MockEIP2981.new({from: another6});
    });

    it('override test', async function () {
      await truffleAssert.reverts(registry.overrideAddress(owner, mockContract.address), "Invalid input");
      await truffleAssert.reverts(registry.overrideAddress(mockContract.address, owner), "Invalid input");
      await truffleAssert.reverts(registry.overrideAddress(mockContract.address, mockManifold.address, {from: another6}));
      await truffleAssert.reverts(registry.overrideAddress(mockManifold.address, mockManifold.address, {from: another6}), "Must be contract owner to override");
      await registry.overrideAddress(mockContract.address, mockManifold.address, {from: owner});
      await registry.overrideAddress(mockManifold.address, mockFoundation.address, {from: another2});
    });

    it('getRoyalty test', async function () {
      var unallocatedTokenId = 1;
      var manifoldTokenId = 2;
      var foundationTokenId = 3;
      var raribleV1TokenId = 4;
      var raribleV2TokenId = 5;
      var eip2981TokenId = 6;

      var unallocatedBps = 100;
      var manifoldBps = 200;
      var foundationBps = 300;
      var raribleV1Bps = 400;
      var raribleV2Bps = 500;
      var eip2981Bps = 600;

      await mockManifold.setRoyalties(manifoldTokenId, [another2], [manifoldBps]);
      await mockFoundation.setRoyalties(foundationTokenId, [another3], [foundationBps]);
      await mockRaribleV1.setRoyalties(raribleV1TokenId, [another4], [raribleV1Bps]);
      await mockRaribleV2.setRoyalties(raribleV2TokenId, [another5], [raribleV2Bps]);
      await mockEIP2981.setRoyalties(eip2981TokenId, [another6], [eip2981Bps]);

      var value = 10000;
      var result;

      result = await registry.getRoyalty(mockManifold.address, manifoldTokenId, value);
      assert.equal(result[0][0], another2);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*manifoldBps/10000));
        
      result = await registry.getRoyalty(mockFoundation.address, foundationTokenId, value);
      assert.equal(result[0][0], another3);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*foundationBps/10000));
        
      result = await registry.getRoyalty(mockRaribleV1.address, raribleV1TokenId, value);
      assert.equal(result[0][0], another4);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*raribleV1Bps/10000));
        
      result = await registry.getRoyalty(mockRaribleV2.address, raribleV2TokenId, value);
      assert.equal(result[0][0], another5);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*raribleV2Bps/10000));
        
      result = await registry.getRoyalty(mockEIP2981.address, eip2981TokenId, value);
      assert.equal(result[0][0], another6);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*eip2981Bps/10000));

      result = await registry.getRoyalty(mockContract.address, unallocatedTokenId, value);
      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      // Override royalty logic
      await registry.overrideAddress(mockContract.address, mockManifold.address, {from: owner});
      result = await registry.getRoyalty(mockContract.address, unallocatedTokenId, value);
      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      // Set royalty
      await mockManifold.setRoyalties(unallocatedTokenId, [another1], [unallocatedBps]);
      result = await registry.getRoyalty(mockContract.address, unallocatedTokenId, value);
      assert.equal(result[0][0], another1);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*unallocatedBps/10000));      
    });

  });
});