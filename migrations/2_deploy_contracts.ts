const InvalidPresaleContract = artifacts.require('InvalidPresale');

module.exports = function (deployer: Truffle.Deployer) {
  deployer.deploy(InvalidPresaleContract, [], false);
};
