const IcpPriceOracle = artifacts.require('IcpPriceOracle')

module.exports = function (deployer) {
  deployer.deploy(IcpPriceOracle)
}