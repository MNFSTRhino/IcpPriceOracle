// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./CallerContractInterface.sol";
contract IcpPriceOracle is Ownable {
  uint private randNonce = 0;
  uint private modulus = 1000;
  mapping(uint256=>bool) pendingRequests;
  event GetLatestIcpPriceEvent(address callerAddress, uint id);
  event SetLatestIcpPriceEvent(uint256 icpPrice, address callerAddress);
  function getLatestIcpPrice() public returns (uint256) {
    randNonce++;
    uint id = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % modulus;
    pendingRequests[id] = true;
    emit GetLatestIcpPriceEvent(msg.sender, id);
    return id;
  }
  function setLatestIcpPrice(uint256 _icpPrice, address _callerAddress, uint256 _id) public onlyOwner {
    require(pendingRequests[_id], "This request is not in my pending list.");
    delete pendingRequests[_id];
    CallerContractInterface callerContractInstance;
    callerContractInstance = CallerContractInterface(_callerAddress);
    callerContractInstance.callback(_icpPrice, _id);
    emit SetLatestIcpPriceEvent(_icpPrice, _callerAddress);  
    }
}
