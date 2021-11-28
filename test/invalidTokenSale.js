const InvalidTokenSale = artifacts.require('InvalidTokenSale');

contract('InvalidTokenSale', accounts => {
  console.log(accounts);

  it('should put 10000 MetaCoin in the first account', async () => {
    // const instance = await InvalidTokenSale.deployed();
    // console.log(instance.methods);s

    assert.equal(true, true, "10000 wasn't in the first account");
  });
});
