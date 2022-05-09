const truffleAssert = require('truffle-assertions');

const MockKODAV2 = artifacts.require('MockKODAV2');
const KODAV2Override = artifacts.require('KODAV2Override');

contract('KODAV2Override', function ([...accounts]) {

  const [owner, random] = accounts;

  describe('KODAV2Override logic test', function () {
    var override, kodav2;

    beforeEach(async function () {
      override = await KODAV2Override.new({from: owner});
      kodav2 = await MockKODAV2.new({from: owner});
    });

    it('Can determine the correct commission', async function () {
      const _1Eth = web3.utils.toWei('1', 'ether');
      const {receivers, amounts} = await override.getKODAV2RoyaltyInfo(kodav2.address, '1234', _1Eth);

      // We know that from MockKODAV2 we have two recipients and the total always adds up to 85%
      // We have a royalty value of 10% and sale price of 1 ETH = 100000000000000000 WEI

      // 0x3f8C962eb167aD2f80C72b5F933511CcDF0719D4 = 84% / 85 * 100 = 98.823529412% of royalty fee
      const receiver1 = receivers[0];
      assert.equal(receiver1, '0x3f8C962eb167aD2f80C72b5F933511CcDF0719D4');
      const amount1 = amounts[0];
      assert.deepEqual(amount1.toString(), '98823529411764696');

      // 0xEEedc9941fb405D1ea90E6FD37d482C361e89Acd = 1% / 85 * 100 = 1.176470588% of royalty fee
      const receiver2 = receivers[1];
      assert.equal(receiver2, '0xEEedc9941fb405D1ea90E6FD37d482C361e89Acd');
      const amount2 = amounts[1];
      assert.deepEqual(amount2.toString(), '1176470588235294');
    });

    it('Only owner can update the commission', async function () {
      await truffleAssert.reverts(
        override.updateCreatorRoyalties('1000000', {from: random}),
        'Ownable: caller is not the owner'
      );
    });

    it('Updating the commission with emit an event', async function () {
      const result = await override.updateCreatorRoyalties('1250000', {from: owner});
      truffleAssert.eventEmitted(result, 'CreatorRoyaltiesFeeUpdated', (ev) => {
        return ev._oldCreatorRoyaltiesFee.toString() === '1000000' && ev._newCreatorRoyaltiesFee.toString() === '1250000';
      }, 'CreatorRoyaltiesFeeUpdated should be emitted with correct parameters');
    });

    it('Will revert if we dont know the edition ID of the token', async function () {
      await truffleAssert.reverts(
        override.getKODAV2RoyaltyInfo(kodav2.address, '0', '1234'),
        'Edition not found for token ID'
      );
    });

  });
});
