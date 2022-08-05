const Mintsclub = artifacts.require("Mintsclub");

module.exports = function (deployer) {
  deployer.deploy(Mintsclub, "Testtoken");
};
