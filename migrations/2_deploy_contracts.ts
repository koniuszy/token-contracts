const InvalidTokenSaleContract = artifacts.require('InvalidTokenSale');

module.exports = function (deployer: Truffle.Deployer) {
  deployer.deploy(InvalidTokenSaleContract, [], false);
};
