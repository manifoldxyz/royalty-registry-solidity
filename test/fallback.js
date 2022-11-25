const truffleAssert = require("truffle-assertions");
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const RoyaltyRegistry = artifacts.require("RoyaltyRegistry");
const RoyaltyEngineV2 = artifacts.require("RoyaltyEngineV2");
const MockContract = artifacts.require("MockContract");
const MockManifold = artifacts.require("MockManifold");
const MockRoyaltyLookUp = artifacts.require("MockRoyaltyLookUp");
const MockEIP2981 = artifacts.require("MockEIP2981");

contract("Registry", function ([...accounts]) {
  const [owner, random, defaultDeployer, manifoldDeployer, eip2981Deployer] =
    accounts;

  describe("Registry", function () {
    var registry;
    var engine;
    var mockContract;
    var randomContract;
    var mockManifold;
    var mockLockup;
    var mockEIP2981;

    beforeEach(async function () {
      registry = await deployProxy(RoyaltyRegistry, {
        initializer: "initialize",
        from: owner,
      });
      mockContract = await MockContract.new({ from: defaultDeployer });
      randomContract = await MockContract.new({ from: defaultDeployer });
      mockManifold = await MockManifold.new({ from: manifoldDeployer });
      mockLockup = await MockRoyaltyLookUp.new({ from: manifoldDeployer });
      mockEIP2981 = await MockEIP2981.new({ from: eip2981Deployer });
    });

    it("reverts if non owner sets fallback address", async function () {
      engine = await deployProxy(RoyaltyEngineV2, [registry.address], {
        initializer: "initialize",
        from: owner,
      });
      await truffleAssert.reverts(
        engine.setFallbackRoyaltyLookup(mockLockup.address, {
          from: eip2981Deployer,
        }),
        "Ownable: caller is not the owner"
      );
    });

    it("fallbacks if lookup address not found", async function () {
      engine = await deployProxy(RoyaltyEngineV2, [registry.address], {
        initializer: "initialize",
        from: owner,
      });

      var fallbackedTokenId = 0;
      var fallbackBps1 = 100;
      var fallbackBps2 = 200;
      var eip2981Bps = 300;
      var value = 10000;
      var result;

      // 1) No royalty if no override and no fallback
      result = await engine.getRoyaltyView(
        randomContract.address,
        fallbackedTokenId,
        1000
      );

      assert.equal(result[0].length, 0);
      assert.equal(result[1].length, 0);

      // 2) Get royalty from fallback registry
      await mockLockup.setTest(
        randomContract.address,
        fallbackedTokenId,
        [manifoldDeployer, random],
        [fallbackBps1, fallbackBps2]
      );

      await engine.setFallbackRoyaltyLookup(mockLockup.address);

      result = await engine.getRoyaltyView(
        randomContract.address,
        fallbackedTokenId,
        value
      );
      assert.equal(result[0].length, 2);
      assert.equal(result[1].length, 2);
      assert.equal(result[0][0], manifoldDeployer);
      assert.deepEqual(
        result[1][0],
        web3.utils.toBN((value * fallbackBps1) / 10000)
      );
      assert.equal(result[0][1], random);
      assert.deepEqual(
        result[1][1],
        web3.utils.toBN((value * fallbackBps2) / 10000)
      );

      await mockEIP2981.setRoyalties(
        fallbackedTokenId,
        [eip2981Deployer],
        [eip2981Bps]
      );

      // 3) Get royalty from override
      await registry.setRoyaltyLookupAddress(
        randomContract.address,
        mockEIP2981.address,
        { from: defaultDeployer }
      );

      result = await engine.getRoyaltyView(
        randomContract.address,
        fallbackedTokenId,
        value
      );

      assert.equal(result[0].length, 1);
      assert.equal(result[1].length, 1);
      assert.equal(result[0][0], eip2981Deployer);
      assert.deepEqual(
        result[1][0],
        web3.utils.toBN((value * eip2981Bps) / 10000)
      );
    });
  });
});
