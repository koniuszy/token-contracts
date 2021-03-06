const InvalidPresale = artifacts.require('InvalidPresale');

function toEther(v: BN) {
  return web3.utils.fromWei(v, 'ether');
}

function toBn(v: number | string) {
  return web3.utils.toBN(v);
}

contract('InvalidPresale', ([owner, ...accounts]) => {
  const ETHER = toBn(web3.utils.toWei('1', 'ether'));

  it('should charge each address for allocation the same gas amount', async () => {
    const allowedAccounts = [...accounts];
    allowedAccounts.pop();
    const instance = await InvalidPresale.deployed();
    await instance.startSale(ETHER, ETHER + '000', ETHER + '00000', ETHER + '0000');
    await instance.addAllowedParticipants(allowedAccounts);
    const initialBalances = (await Promise.all(allowedAccounts.map(a => web3.eth.getBalance(a)))).map(toBn);

    const value = ETHER;
    await Promise.all(allowedAccounts.map(a => instance.allocate({ from: a, value })));

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
