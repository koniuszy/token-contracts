const InvalidTokenSale = artifacts.require('InvalidTokenSale');

function toEther(v) {
  return web3.utils.fromWei(v, 'ether');
}

function toBn(v) {
  return web3.utils.toBN(v);
}

contract('InvalidTokenSale', ([owner, ...accounts]) => {
  const ETHER = toBn(web3.utils.toWei('1', 'ether'));

  it('should charge each address for allocation the same gas amount', async () => {
    const allowedAccounts = [...accounts];
    allowedAccounts.pop();
    const instance = await InvalidTokenSale.deployed([], true);
    await instance.startSale(ETHER, ETHER + '000', ETHER + '00000', ETHER + '0000');
    await instance.addAllowedParticipants(allowedAccounts);
    const initialBalances = (await Promise.all(allowedAccounts.map(a => web3.eth.getBalance(a)))).map(toBn);

    const value = ETHER;
    await Promise.all(
      allowedAccounts.map(a =>
        instance.allocate({ from: a, value }).then(() => instance.allowedParticipants().then(console.log))
      )
    );

    const gasPriceList = await Promise.all(
      allowedAccounts.map(async (a, index) => {
        const currentBalance = toBn(await web3.eth.getBalance(a));
        return toEther(initialBalances[index].sub(currentBalance));
      })
    );

    const totalAllocated = await instance.totalAllocated();
    const allocationsCount = toBn(allowedAccounts.length);
    assert.equal(totalAllocated.toString(), value.mul(allocationsCount).toString(), 'the total allocation is wrong');

    const [firstAllocationMayBeCheaper, ...theSameGasList] = gasPriceList;
    const firstGasPrice = theSameGasList[0];
    theSameGasList.forEach(gasPrice => {
      assert.equal(
        firstGasPrice,
        gasPrice,
        `the gas price differ from the first allocation, gas prices: ${gasPriceList}`
      );
    });
  });
});
