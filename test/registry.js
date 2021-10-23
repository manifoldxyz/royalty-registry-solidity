const truffleAssert = require('truffle-assertions');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const RoyaltyRegistry = artifacts.require("RoyaltyRegistry");
const RoyaltyEngineV1 = artifacts.require("RoyaltyEngineV1")
const MockContract = artifacts.require("MockContract");
const MockManifold = artifacts.require("MockManifold");
const MockFoundation = artifacts.require("MockFoundation");
const MockFoundationTreasury = artifacts.require("MockFoundationTreasury");
const MockRaribleV1 = artifacts.require("MockRaribleV1");
const MockRaribleV2 = artifacts.require("MockRaribleV2");
const MockEIP2981 = artifacts.require("MockEIP2981");
const MockRoyaltyPayer = artifacts.require("MockRoyaltyPayer");
const MockNiftyBuilder = artifacts.require("MockNiftyBuilder");
const MockNiftyRegistry = artifacts.require("MockNiftyRegistry");
const MockERC1155PresetMinterPauser = artifacts.require("MockERC1155PresetMinterPauser");

contract('Registry', function ([...accounts]) {
  const [
    owner,
    random,
    defaultDeployer,
    manifoldDeployer,
    foundationDeployer,
    raribleV1Deployer,
    raribleV2Deployer,
    eip2981Deployer,
    niftyDeployer,
    erc1155PresetDeployer,
  ] = accounts;

  describe('Registry', function() {
    var registry;
    var engine;
    var mockContract;
    var randomContract;
    var mockManifold;
    var mockFoundation;
    var mockFoundationTreasury;
    var mockRaribleV1;
    var mockRaribleV2;
    var mockEIP2981;
    var mockRoyaltyPayer;
    var mockNiftyRegistry;
    var mockNiftyBuilder;
    var mockERC1155PresetMinterPauser;

    beforeEach(async function () {
      registry = await deployProxy(RoyaltyRegistry, {initializer: "initialize", from:owner});

      mockContract = await MockContract.new({from: defaultDeployer});
      randomContract = await MockContract.new({from: defaultDeployer})
      mockManifold = await MockManifold.new({from: manifoldDeployer});
      mockFoundation = await MockFoundation.new({from: foundationDeployer});
      mockFoundationTreasury = await MockFoundationTreasury.new({from: foundationDeployer});
      mockRaribleV1 = await MockRaribleV1.new({from: raribleV1Deployer});
      mockRaribleV2 = await MockRaribleV2.new({from: raribleV2Deployer});
      mockEIP2981 = await MockEIP2981.new({from: eip2981Deployer});
      mockRoyaltyPayer = await MockRoyaltyPayer.new();
      mockNiftyRegistry = await MockNiftyRegistry.new(niftyDeployer);
      mockNiftyBuilder = await MockNiftyBuilder.new(mockNiftyRegistry.address);
      mockERC1155PresetMinterPauser = await MockERC1155PresetMinterPauser.new({from: erc1155PresetDeployer});
    });

    it('override test', async function () {
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(owner, mockContract.address), "Invalid input");
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(mockContract.address, owner), "Invalid input");
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(mockContract.address, mockManifold.address, {from: eip2981Deployer}));
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(mockManifold.address, mockManifold.address, {from: eip2981Deployer}), "Permission denied");
      await registry.setRoyaltyLookupAddress(mockContract.address, mockManifold.address, {from: owner});
      await registry.setRoyaltyLookupAddress(mockManifold.address, mockFoundation.address, {from: manifoldDeployer});
    });

    it('permissions test', async function() {
      assert.equal(false, await registry.overrideAllowed(mockContract.address, {from:random}));
      assert.equal(false, await registry.overrideAllowed(mockManifold.address, {from:random}));
      await mockFoundation.setFoundationTreasury(mockContract.address);
      assert.equal(false, await registry.overrideAllowed(mockFoundation.address, {from:random}));
      assert.equal(false, await registry.overrideAllowed(mockRaribleV1.address, {from:random}));
      assert.equal(false, await registry.overrideAllowed(mockRaribleV2.address, {from:random}));
      assert.equal(false, await registry.overrideAllowed(mockEIP2981.address, {from:random}));
      assert.equal(false, await registry.overrideAllowed(mockNiftyBuilder.address, {from:random}));
      assert.equal(false, await registry.overrideAllowed(mockERC1155PresetMinterPauser.address, {from:random}));

      assert.equal(true, await registry.overrideAllowed(mockManifold.address, {from:manifoldDeployer}));
      assert.equal(true, await registry.overrideAllowed(mockFoundation.address, {from:foundationDeployer}));
      assert.equal(true, await registry.overrideAllowed(mockRaribleV1.address, {from:raribleV1Deployer}));
      assert.equal(true, await registry.overrideAllowed(mockRaribleV2.address, {from:raribleV2Deployer}));
      assert.equal(true, await registry.overrideAllowed(mockEIP2981.address, {from:eip2981Deployer}));
      assert.equal(true, await registry.overrideAllowed(mockNiftyBuilder.address, {from:niftyDeployer}));
      assert.equal(true, await registry.overrideAllowed(mockERC1155PresetMinterPauser.address, {from:erc1155PresetDeployer}));
    })

    it('getRoyalty test', async function () {
      engine = await deployProxy(RoyaltyEngineV1, [registry.address], {initializer: "initialize", from:owner});

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

      await mockManifold.setRoyalties(manifoldTokenId, [manifoldDeployer], [manifoldBps]);
      await mockFoundation.setRoyalties(foundationTokenId, [foundationDeployer], [foundationBps]);
      await mockRaribleV1.setRoyalties(raribleV1TokenId, [raribleV1Deployer], [raribleV1Bps]);
      await mockRaribleV2.setRoyalties(raribleV2TokenId, [raribleV2Deployer], [raribleV2Bps]);
      await mockEIP2981.setRoyalties(eip2981TokenId, [eip2981Deployer], [eip2981Bps]);

      var value = 10000;
      var result;

      result = await engine.getRoyaltyView(randomContract.address, 1, 1000);
      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      result = await engine.getRoyaltyView(mockManifold.address, manifoldTokenId, value);
      assert.equal(result[0][0], manifoldDeployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*manifoldBps/10000));
        
      result = await engine.getRoyaltyView(mockFoundation.address, foundationTokenId, value);
      assert.equal(result[0][0], foundationDeployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*foundationBps/10000));
        
      result = await engine.getRoyaltyView(mockRaribleV1.address, raribleV1TokenId, value);
      assert.equal(result[0][0], raribleV1Deployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*raribleV1Bps/10000));
        
      result = await engine.getRoyaltyView(mockRaribleV2.address, raribleV2TokenId, value);
      assert.equal(result[0][0], raribleV2Deployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*raribleV2Bps/10000));
        
      result = await engine.getRoyaltyView(mockEIP2981.address, eip2981TokenId, value);
      assert.equal(result[0][0], eip2981Deployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*eip2981Bps/10000));

      result = await engine.getRoyaltyView(mockContract.address, unallocatedTokenId, value);
      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      // Override royalty logic
      await registry.setRoyaltyLookupAddress(mockContract.address, mockManifold.address, {from: defaultDeployer});
      result = await engine.getRoyaltyView(mockContract.address, unallocatedTokenId, value);
      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      // Set royalty
      await mockManifold.setRoyalties(unallocatedTokenId, [defaultDeployer], [unallocatedBps]);
      result = await engine.getRoyaltyView(mockContract.address, unallocatedTokenId, value);
      assert.equal(result[0][0], defaultDeployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*unallocatedBps/10000));

      // Simulate paying a royalty and check gas cost
      await mockRoyaltyPayer.deposit({from:owner, value:value*100})
      var tx;
      tx = await mockRoyaltyPayer.payout(engine.address, mockContract.address, 1, value);
      console.log("Payout gas no royalties: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockManifold.address, manifoldTokenId, value);
      console.log("Payout gas manifold: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockFoundation.address, foundationTokenId, value);
      console.log("Payout gas foundation: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockRaribleV1.address, raribleV1TokenId, value);
      console.log("Payout gas rariblev1: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockRaribleV2.address, raribleV2TokenId, value);
      console.log("Payout gas rariblev2: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockEIP2981.address, eip2981TokenId, value);
      console.log("Payout gas eip2981: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockContract.address, unallocatedTokenId, value);
      console.log("Payout gas used with override: %s", tx.receipt.gasUsed);

      // Simulate after running cache
      await engine.getRoyalty(mockManifold.address, manifoldTokenId, value)
      await engine.getRoyalty(mockFoundation.address, foundationTokenId, value)
      await engine.getRoyalty(mockRaribleV1.address, raribleV1TokenId, value)
      await engine.getRoyalty(mockRaribleV2.address, raribleV2TokenId, value)
      await engine.getRoyalty(mockEIP2981.address, eip2981TokenId, value)
      await mockRoyaltyPayer.payout(engine.address, mockContract.address, unallocatedTokenId, value);
      tx = await mockRoyaltyPayer.payout(engine.address, mockContract.address, 1, value);
      console.log("CACHE: Payout gas no royalties: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockManifold.address, manifoldTokenId, value);
      console.log("CACHE: Payout gas manifold: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockFoundation.address, foundationTokenId, value);
      console.log("CACHE: Payout gas foundation: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockRaribleV1.address, raribleV1TokenId, value);
      console.log("CACHE: Payout gas rariblev1: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockRaribleV2.address, raribleV2TokenId, value);
      console.log("CACHE: Payout gas rariblev2: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockEIP2981.address, eip2981TokenId, value);
      console.log("CACHE: Payout gas eip2981: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockContract.address, unallocatedTokenId, value);
      console.log("CACHE: Payout gas used with override: %s", tx.receipt.gasUsed);

      // Foundation override test
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(mockFoundation.address, mockManifold.address, {from: random}));
      // Foundation treasury address with no admin
      await mockFoundation.setFoundationTreasury(mockContract.address);
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(mockFoundation.address, mockManifold.address, {from: random}), "Permission denied");
      // Set to proper treasury
      await mockFoundation.setFoundationTreasury(mockFoundationTreasury.address);
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(mockFoundation.address, mockManifold.address, {from: random}), "Permission denied");
      await mockFoundationTreasury.setAdmin(random);
      await registry.setRoyaltyLookupAddress(mockFoundation.address, mockManifold.address, {from: random})
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(mockFoundation.address, mockManifold.address, {from: defaultDeployer}), "Permission denied");

      // Nifty Gateway override test
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(mockNiftyBuilder.address, mockManifold.address, {from: random}));
      registry.setRoyaltyLookupAddress(mockNiftyBuilder.address, mockManifold.address, {from: niftyDeployer})

      // Openzeppelin AccessControl override test
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(mockERC1155PresetMinterPauser.address, mockManifold.address, {from: random}));
      registry.setRoyaltyLookupAddress(mockERC1155PresetMinterPauser.address, mockManifold.address, {from: erc1155PresetDeployer})

    });

  });
});