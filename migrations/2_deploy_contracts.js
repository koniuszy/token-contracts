const InvalidTokenSale = artifacts.require('InvalidTokenSale');

module.exports = function (deployer) {
  deployer.deploy(InvalidTokenSale, [], false);
};
