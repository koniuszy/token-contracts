const InvalidTokenSale = artifacts.require('InvalidTokenSale');
// const Ownable = artifacts.require('Ownable');

module.exports = function (deployer) {
  deployer.deploy(InvalidTokenSale, [], false);
};
