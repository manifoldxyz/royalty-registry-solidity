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
const MockDigitalaxNFT = artifacts.require("MockDigitalaxNFT");
const MockDigitalaxAccessControls = artifacts.require("MockDigitalaxAccessControls");
const MockArtBlocks = artifacts.require("MockArtBlocks");
const MockArtBlocksOverride = artifacts.require("MockArtBlocksOverride");
const MockERC1155PresetMinterPauser = artifacts.require("MockERC1155PresetMinterPauser");
const MockZora = artifacts.require("ZoraOverride");
const MockKodaV2Override = artifacts.require("MockKODAV2Override");

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
    artBlocksDeployer,
    erc1155PresetDeployer,
    indirectOwner
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
    var mockDigitalaxNFT;
    var mockDigitalaxAccessControls;
    var mockNiftyBuilder;
    var mockArtBlocks;
    var mockArtBlocksOverride;
    var mockERC1155PresetMinterPauser;
    var mockZora;
    var mockIndirectlyOwnedContract;
    var mockDirectOwnerContract;
    var mockKodaV2Override;
    var mockKodaV2;

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
      mockDigitalaxAccessControls = await MockDigitalaxAccessControls.new(owner, {from: owner});
      mockDigitalaxNFT = await MockDigitalaxNFT.new(mockDigitalaxAccessControls.address, {from: owner});
      mockArtBlocks = await MockArtBlocks.new({from: artBlocksDeployer});
      mockArtBlocksOverride = await MockArtBlocksOverride.new({from: artBlocksDeployer});
      mockERC1155PresetMinterPauser = await MockERC1155PresetMinterPauser.new({ from: erc1155PresetDeployer });
      mockZora = await MockZora.new();
      mockIndirectlyOwnedContract = await MockContract.new({from: defaultDeployer});
      mockDirectOwnerContract = await MockContract.new({from: defaultDeployer});
      mockKodaV2 = await MockContract.new({from: defaultDeployer});
      mockKodaV2Override = await MockKodaV2Override.new();
    });

    it('override test', async function () {
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(owner, mockContract.address), "Invalid input");
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(mockContract.address, owner), "Invalid input");
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(mockContract.address, mockManifold.address, {from: eip2981Deployer}));
      await truffleAssert.reverts(registry.setRoyaltyLookupAddress(mockManifold.address, mockManifold.address, {from: eip2981Deployer}), "Permission denied");
      await registry.setRoyaltyLookupAddress(mockContract.address, mockManifold.address, {from: owner});
      await registry.setRoyaltyLookupAddress(mockManifold.address, mockFoundation.address, { from: manifoldDeployer });
      await registry.setRoyaltyLookupAddress(mockContract.address, mockZora.address, { from: owner });

      await mockIndirectlyOwnedContract.transferOwnership(mockDirectOwnerContract.address, { from: defaultDeployer });
      await mockDirectOwnerContract.transferOwnership(indirectOwner, { from: defaultDeployer });
      await registry.setRoyaltyLookupAddress(mockIndirectlyOwnedContract.address, mockManifold.address, { from: owner });
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
      assert.equal(false, await registry.overrideAllowed(mockDigitalaxNFT.address, {from:random}));
      assert.equal(false, await registry.overrideAllowed(mockArtBlocks.address, {from:random}));
      assert.equal(false, await registry.overrideAllowed(mockERC1155PresetMinterPauser.address, { from: random }));
      assert.equal(false, await registry.overrideAllowed(mockZora.address, { from: random }));
      assert.equal(false, await registry.overrideAllowed(mockIndirectlyOwnedContract.address, { from: indirectOwner }));
      assert.equal(false, await registry.overrideAllowed(mockKodaV2Override.address, { from: random }));

      assert.equal(true, await registry.overrideAllowed(mockManifold.address, {from:manifoldDeployer}));
      assert.equal(true, await registry.overrideAllowed(mockFoundation.address, {from:foundationDeployer}));
      assert.equal(true, await registry.overrideAllowed(mockRaribleV1.address, {from:raribleV1Deployer}));
      assert.equal(true, await registry.overrideAllowed(mockRaribleV2.address, {from:raribleV2Deployer}));
      assert.equal(true, await registry.overrideAllowed(mockEIP2981.address, {from:eip2981Deployer}));
      assert.equal(true, await registry.overrideAllowed(mockNiftyBuilder.address, {from:niftyDeployer}));
      assert.equal(true, await registry.overrideAllowed(mockDigitalaxNFT.address, {from:owner}));
      assert.equal(true, await registry.overrideAllowed(mockArtBlocks.address, {from:artBlocksDeployer}));
      assert.equal(true, await registry.overrideAllowed(mockERC1155PresetMinterPauser.address, { from: erc1155PresetDeployer }));
      assert.equal(true, await registry.overrideAllowed(mockZora.address, { from: owner }))

      assert.equal(true, await registry.overrideAllowed(mockKodaV2Override.address, { from: owner }))

      await mockIndirectlyOwnedContract.transferOwnership(mockDirectOwnerContract.address, { from: defaultDeployer });
      await mockDirectOwnerContract.transferOwnership(indirectOwner, { from: defaultDeployer });
      assert.equal(true, await registry.overrideAllowed(mockIndirectlyOwnedContract.address, { from: indirectOwner }));
    });

    it('getRoyalty test', async function () {
      engine = await deployProxy(RoyaltyEngineV1, [registry.address], {initializer: "initialize", from:owner});

      var unallocatedTokenId = 1;
      var manifoldTokenId = 2;
      var foundationTokenId = 3;
      var raribleV1TokenId = 4;
      var raribleV2TokenId = 5;
      var eip2981TokenId = 6;
      var artBlocksTokenId = 7;
      var indirectlyOwnedTokenId = 8;

      var unallocatedBps = 100;
      var manifoldBps = 200;
      var foundationBps = 300;
      var raribleV1Bps = 400;
      var raribleV2Bps = 500;
      var eip2981Bps = 600;
      var randomBps = 100;
      var indirectlyOwnedTokenBps = 500;

      var value = 10000;
      var result;

      await mockManifold.setRoyalties(manifoldTokenId, [manifoldDeployer, random], [manifoldBps, randomBps]);
      await mockFoundation.setRoyalties(foundationTokenId, [foundationDeployer, random], [foundationBps, randomBps]);
      await mockRaribleV1.setRoyalties(raribleV1TokenId, [raribleV1Deployer, random], [raribleV1Bps, randomBps]);
      await mockRaribleV2.setRoyalties(raribleV2TokenId, [raribleV2Deployer, random], [raribleV2Bps, randomBps]);

      result = await engine.getRoyaltyView(mockManifold.address, manifoldTokenId, value);
      assert.equal(result[0].length, 2);
      assert.equal(result[1].length, 2);
      assert.equal(result[0][0], manifoldDeployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*manifoldBps/10000));
      assert.equal(result[0][1], random);
      assert.deepEqual(result[1][1], web3.utils.toBN(value*randomBps/10000));

      result = await engine.getRoyaltyView(mockFoundation.address, foundationTokenId, value);
      assert.equal(result[0].length, 2);
      assert.equal(result[1].length, 2);
      assert.equal(result[0][0], foundationDeployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*foundationBps/10000));
      assert.equal(result[0][1], random);
      assert.deepEqual(result[1][1], web3.utils.toBN(value*randomBps/10000));

      result = await engine.getRoyaltyView(mockRaribleV1.address, raribleV1TokenId, value);
      assert.equal(result[0].length, 2);
      assert.equal(result[1].length, 2);
      assert.equal(result[0][0], raribleV1Deployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*raribleV1Bps/10000));
      assert.equal(result[0][1], random);
      assert.deepEqual(result[1][1], web3.utils.toBN(value*randomBps/10000));

      result = await engine.getRoyaltyView(mockRaribleV2.address, raribleV2TokenId, value);
      assert.equal(result[0].length, 2);
      assert.equal(result[1].length, 2);
      assert.equal(result[0][0], raribleV2Deployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*raribleV2Bps/10000));
      assert.equal(result[0][1], random);
      assert.deepEqual(result[1][1], web3.utils.toBN(value*randomBps/10000));

      await mockManifold.setRoyalties(manifoldTokenId, [manifoldDeployer], [manifoldBps]);
      await mockFoundation.setRoyalties(foundationTokenId, [foundationDeployer], [foundationBps]);
      await mockRaribleV1.setRoyalties(raribleV1TokenId, [raribleV1Deployer], [raribleV1Bps]);
      await mockRaribleV2.setRoyalties(raribleV2TokenId, [raribleV2Deployer], [raribleV2Bps]);
      await mockEIP2981.setRoyalties(eip2981TokenId, [eip2981Deployer], [eip2981Bps]);

      result = await engine.getRoyaltyView(randomContract.address, 1, 1000);
      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      result = await engine.getRoyaltyView(mockManifold.address, manifoldTokenId, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[1].length, 1);
      assert.equal(result[0][0], manifoldDeployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*manifoldBps/10000));

      result = await engine.getRoyaltyView(mockFoundation.address, foundationTokenId, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[1].length, 1);
      assert.equal(result[0][0], foundationDeployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*foundationBps/10000));

      result = await engine.getRoyaltyView(mockRaribleV1.address, raribleV1TokenId, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[1].length, 1);
      assert.equal(result[0][0], raribleV1Deployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*raribleV1Bps/10000));

      result = await engine.getRoyaltyView(mockRaribleV2.address, raribleV2TokenId, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[1].length, 1);
      assert.equal(result[0][0], raribleV2Deployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*raribleV2Bps/10000));

      result = await engine.getRoyaltyView(mockEIP2981.address, eip2981TokenId, value);
      assert.equal(result[0].length, 1);
      assert.equal(result[1].length, 1);
      assert.equal(result[0][0], eip2981Deployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*eip2981Bps/10000));

      result = await engine.getRoyaltyView(mockContract.address, unallocatedTokenId, value);
      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      result = await engine.getRoyaltyView(mockIndirectlyOwnedContract.address, indirectlyOwnedTokenId, value);
      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      // Override royalty logic
      await registry.setRoyaltyLookupAddress(mockContract.address, mockManifold.address, {from: defaultDeployer});
      result = await engine.getRoyaltyView(mockContract.address, unallocatedTokenId, value);
      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      await mockIndirectlyOwnedContract.transferOwnership(mockDirectOwnerContract.address, { from: defaultDeployer });
      await mockDirectOwnerContract.transferOwnership(indirectOwner, { from: defaultDeployer });
      await registry.setRoyaltyLookupAddress(mockIndirectlyOwnedContract.address, mockManifold.address, {from: indirectOwner});
      result = await engine.getRoyaltyView(mockIndirectlyOwnedContract.address, indirectlyOwnedTokenId, value);
      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      // Set royalty
      await mockManifold.setRoyalties(unallocatedTokenId, [defaultDeployer], [unallocatedBps]);
      result = await engine.getRoyaltyView(mockContract.address, unallocatedTokenId, value);
      assert.equal(result[0][0], defaultDeployer);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*unallocatedBps/10000));

      // Override royalty logic for KODAV2
      await registry.setRoyaltyLookupAddress(mockKodaV2.address, mockKodaV2Override.address, {from: owner});
      const royaltyLookupAddress = await registry.getRoyaltyLookupAddress(mockKodaV2.address);
      assert.deepEqual(royaltyLookupAddress, mockKodaV2Override.address);
      result = await engine.getRoyaltyView(mockKodaV2.address, unallocatedTokenId, value);
      assert.equal(result[0].length, 2);
      assert.equal(result[1].length, 2)

      await mockManifold.setRoyalties(indirectlyOwnedTokenId, [indirectOwner], [indirectlyOwnedTokenBps]);
      result = await engine.getRoyaltyView(mockIndirectlyOwnedContract.address, indirectlyOwnedTokenId, value);
      assert.equal(result[0][0], indirectOwner);
      assert.deepEqual(result[1][0], web3.utils.toBN(value*indirectlyOwnedTokenBps/10000));

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
      tx = await mockRoyaltyPayer.payout(engine.address, mockArtBlocksOverride.address, artBlocksTokenId, value);
      console.log("Payout gas used with art blocks override: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockKodaV2Override.address, unallocatedTokenId, value);
      console.log("Payout gas used with KODA V2 override: %s", tx.receipt.gasUsed);

      var indirectOwnerBalanceBefore = BigInt(await web3.eth.getBalance(indirectOwner));
      tx = await mockRoyaltyPayer.payout(engine.address, mockIndirectlyOwnedContract.address, indirectlyOwnedTokenId, value);
      console.log("Payout gas used with indirect override: %s", tx.receipt.gasUsed);
      var indirectOwnerBalanceAfter = BigInt(await web3.eth.getBalance(indirectOwner));
      var balanceDiff = indirectOwnerBalanceAfter - indirectOwnerBalanceBefore;
      balanceDiff = Number(balanceDiff);
      assert.equal(balanceDiff, value*indirectlyOwnedTokenBps/10000);

      // Simulate after running cache
      await engine.getRoyalty(mockManifold.address, manifoldTokenId, value)
      await engine.getRoyalty(mockFoundation.address, foundationTokenId, value)
      await engine.getRoyalty(mockRaribleV1.address, raribleV1TokenId, value)
      await engine.getRoyalty(mockRaribleV2.address, raribleV2TokenId, value)
      await engine.getRoyalty(mockEIP2981.address, eip2981TokenId, value)
      await engine.getRoyalty(mockArtBlocksOverride.address, artBlocksTokenId, value)

      await engine.getRoyalty(mockKodaV2Override.address, unallocatedTokenId, value);
      assert.equal(await engine.getCachedRoyaltySpec(mockKodaV2.address), 9);

      await engine.getRoyalty(mockIndirectlyOwnedContract.address, indirectlyOwnedTokenId, value)

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
      tx = await mockRoyaltyPayer.payout(engine.address, mockArtBlocksOverride.address, artBlocksTokenId, value);
      console.log("CACHE: Payout gas used with art blocks override: %s", tx.receipt.gasUsed);
      tx = await mockRoyaltyPayer.payout(engine.address, mockIndirectlyOwnedContract.address, indirectlyOwnedTokenId, value);
      console.log("CACHE: Payout gas used with override: %s", tx.receipt.gasUsed);

      indirectOwnerBalanceBefore = BigInt(await web3.eth.getBalance(indirectOwner));
      tx = await mockRoyaltyPayer.payout(engine.address, mockIndirectlyOwnedContract.address, indirectlyOwnedTokenId, value);
      console.log("Payout gas used with indirect override: %s", tx.receipt.gasUsed);
      indirectOwnerBalanceAfter = BigInt(await web3.eth.getBalance(indirectOwner));
      balanceDiff = indirectOwnerBalanceAfter - indirectOwnerBalanceBefore;
      balanceDiff = Number(balanceDiff);
      assert.equal(balanceDiff, value*indirectlyOwnedTokenBps/10000);

      tx = await mockRoyaltyPayer.payout(engine.address, mockKodaV2Override.address, unallocatedTokenId, value);
      console.log("CACHE: Payout gas used with KODA V2 override: %s", tx.receipt.gasUsed);

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

      // Check spec cache
      assert.equal(await engine.getCachedRoyaltySpec(mockEIP2981.address), 5);
      await engine.invalidateCachedRoyaltySpec(mockEIP2981.address, {from:random});
      assert.equal(await engine.getCachedRoyaltySpec(mockEIP2981.address), 0);
    });

    it('invalid royalties test', async function () {
      engine = await deployProxy(RoyaltyEngineV1, [registry.address], {initializer: "initialize", from:owner});

      var unallocatedTokenId = 1;
      var manifoldTokenId = 2;
      var foundationTokenId = 3;
      var raribleV1TokenId = 4;
      var raribleV2TokenId = 5;
      var eip2981TokenId = 6;
      var artBlocksTokenId = 7;

      await mockManifold.setRoyalties(manifoldTokenId, [manifoldDeployer], [10000]);
      await mockFoundation.setRoyalties(foundationTokenId, [foundationDeployer], [10000]);
      await mockRaribleV1.setRoyalties(raribleV1TokenId, [raribleV1Deployer], [10000]);
      await mockRaribleV2.setRoyalties(raribleV2TokenId, [raribleV2Deployer], [10000]);
      await mockEIP2981.setRoyalties(eip2981TokenId, [eip2981Deployer], [10000]);
      await mockArtBlocksOverride.setRoyalties(10000);

      var value = 10000;

      await truffleAssert.reverts(engine.getRoyaltyView(mockManifold.address, manifoldTokenId, value), "Invalid royalty amount");
      await truffleAssert.reverts(engine.getRoyaltyView(mockFoundation.address, foundationTokenId, value), "Invalid royalty amount");
      await truffleAssert.reverts(engine.getRoyaltyView(mockRaribleV1.address, raribleV1TokenId, value), "Invalid royalty amount");
      await truffleAssert.reverts(engine.getRoyaltyView(mockRaribleV2.address, raribleV2TokenId, value), "Invalid royalty amount");
      await truffleAssert.reverts(engine.getRoyaltyView(mockEIP2981.address, eip2981TokenId, value), "Invalid royalty amount");
      await truffleAssert.reverts(engine.getRoyaltyView(mockArtBlocksOverride.address, artBlocksTokenId, value), "Invalid royalty amount");

      // Set back to normal values
      var manifoldBps = 2000;
      var foundationBps = 3000;
      var raribleV1Bps = 4000;
      var raribleV2Bps = 5000;
      var eip2981Bps = 6000;
      var artBlocksBps = 7000;

      await mockManifold.setRoyalties(manifoldTokenId, [defaultDeployer, manifoldDeployer], [manifoldBps, manifoldBps]);
      await mockFoundation.setRoyalties(foundationTokenId, [foundationDeployer], [foundationBps]);
      await mockRaribleV1.setRoyalties(raribleV1TokenId, [raribleV1Deployer, raribleV2Deployer], [raribleV1Bps, raribleV2Bps]);
      await mockRaribleV2.setRoyalties(raribleV2TokenId, [raribleV2Deployer], [raribleV2Bps]);
      await mockEIP2981.setRoyalties(eip2981TokenId, [eip2981Deployer], [eip2981Bps]);
      await mockArtBlocksOverride.setRoyalties(artBlocksBps);

      // Simulate paying a royalty and check gas cost
      await mockRoyaltyPayer.deposit({from:owner, value:value*100})
      await mockRoyaltyPayer.payout(engine.address, mockContract.address, 1, value);
      await mockRoyaltyPayer.payout(engine.address, mockManifold.address, manifoldTokenId, value);
      await mockRoyaltyPayer.payout(engine.address, mockFoundation.address, foundationTokenId, value);
      await mockRoyaltyPayer.payout(engine.address, mockRaribleV1.address, raribleV1TokenId, value);
      await mockRoyaltyPayer.payout(engine.address, mockRaribleV2.address, raribleV2TokenId, value);
      await mockRoyaltyPayer.payout(engine.address, mockEIP2981.address, eip2981TokenId, value);
      await mockRoyaltyPayer.payout(engine.address, mockArtBlocksOverride.address, artBlocksTokenId, value);
      await mockRoyaltyPayer.payout(engine.address, mockIndirectlyOwnedContract.address, 1, value);

      // Simulate after running cache
      await engine.getRoyalty(mockManifold.address, manifoldTokenId, value)
      await engine.getRoyalty(mockFoundation.address, foundationTokenId, value)
      await engine.getRoyalty(mockRaribleV1.address, raribleV1TokenId, value)
      await engine.getRoyalty(mockRaribleV2.address, raribleV2TokenId, value)
      await engine.getRoyalty(mockEIP2981.address, eip2981TokenId, value)
      await engine.getRoyalty(mockArtBlocksOverride.address, artBlocksTokenId, value)

      // Set to bad values again
      await mockManifold.setRoyalties(manifoldTokenId, [defaultDeployer, manifoldDeployer], [4000, 6000]);
      await mockFoundation.setRoyalties(foundationTokenId, [foundationDeployer], [10000]);
      await mockRaribleV1.setRoyalties(raribleV1TokenId, [raribleV1Deployer, raribleV2Deployer], [4000, 6000]);
      await mockRaribleV2.setRoyalties(raribleV2TokenId, [raribleV2Deployer], [10000]);
      await mockEIP2981.setRoyalties(eip2981TokenId, [eip2981Deployer], [10000]);
      await mockArtBlocksOverride.setRoyalties(10000);

      await truffleAssert.reverts(engine.getRoyaltyView(mockManifold.address, manifoldTokenId, value), "Invalid royalty amount");
      await truffleAssert.reverts(engine.getRoyaltyView(mockFoundation.address, foundationTokenId, value), "Invalid royalty amount");
      await truffleAssert.reverts(engine.getRoyaltyView(mockRaribleV1.address, raribleV1TokenId, value), "Invalid royalty amount");
      await truffleAssert.reverts(engine.getRoyaltyView(mockRaribleV2.address, raribleV2TokenId, value), "Invalid royalty amount");
      await truffleAssert.reverts(engine.getRoyaltyView(mockEIP2981.address, eip2981TokenId, value), "Invalid royalty amount");
      await truffleAssert.reverts(engine.getRoyaltyView(mockArtBlocksOverride.address, artBlocksTokenId, value), "Invalid royalty amount");
    });

  });
});
