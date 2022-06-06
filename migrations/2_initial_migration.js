var Pupper = artifacts.require("./Pupper.sol");

module.exports = function(deployer) {
  deployer.deploy(Pupper);
};
