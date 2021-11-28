const InvalidTokenSale = artifacts.require('InvalidTokenSale');
const Ownable = artifacts.require('Ownable');

module.exports = function (deployer) {
  deployer.deploy(Ownable);
  deployer.link(Ownable, InvalidTokenSale);
  deployer.deploy(InvalidTokenSale);
};
