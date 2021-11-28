const MetaCoin = artifacts.require('MetaCoin');
// const Ownable = artifacts.require('Ownable');

module.exports = function (deployer) {
  // deployer.deploy(Ownable);
  // deployer.link(Ownable, InvalidTokenSale);
  deployer.deploy(MetaCoin);
};
