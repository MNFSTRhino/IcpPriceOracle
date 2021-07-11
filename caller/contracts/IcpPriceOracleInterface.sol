// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
abstract contract IcpPriceOracleInterface {
  function getLatestIcpPrice() public virtual returns (uint256);
}
