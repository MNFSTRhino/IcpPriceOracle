// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./CallerContractInterface.sol";
contract IcpPriceOracle is AccessControl {
  bytes32 private constant OWNERS = keccak256("OWNERS");
  bytes32 private constant ORACLES = keccak256("ORACLES");
  using SafeMath for uint256;
  uint private randNonce = 0;
  uint private modulus = 1000;
  uint private numOracles = 0;
  uint private THRESHOLD = 0;
  mapping(uint256=>bool) pendingRequests;
  struct Response {
    address oracleAddress;
    address callerAddress;
    uint256 icpPrice;
  }
  mapping (uint256=>Response[]) public requestIdToResponse;
  event GetLatestIcpPriceEvent(address callerAddress, uint id);
  event SetLatestIcpPriceEvent(uint256 icpPrice, address callerAddress);
  event AddOracleEvent(address oracleAddress);
  event RemoveOracleEvent(address oracleAddress);
  event SetThresholdEvent(uint threshold);
  constructor (address _owner) {
    _setupRole(OWNERS, _owner);
  }
  function addOracle(address _oracle) public {
    require(hasRole(OWNERS, msg.sender), "Not an owner!");
    require(!hasRole(ORACLES, _oracle), "Already an oracle!");
    _setupRole(ORACLES, _oracle);
    emit AddOracleEvent(_oracle);
  }
  function removeOracle(address _oracle) public {
    require(hasRole(OWNERS, msg.sender), "Not an owner!");
    require(hasRole(ORACLES, _oracle), "Not an oracle!");
    require(numOracles > 1, "Do not remove the last oracle!");
    revokeRole(ORACLES, _oracle);
    numOracles--;
    emit RemoveOracleEvent(_oracle);
  }
  function setThreshold (uint _threshold) public {
    require(hasRole(OWNERS, msg.sender), "Not an owner!");
    THRESHOLD = _threshold;
    emit SetThresholdEvent(THRESHOLD);
  }
  function getLatestIcpPrice() public returns (uint256) {
    randNonce++;
    uint id = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % modulus;
    pendingRequests[id] = true;
    emit GetLatestIcpPriceEvent(msg.sender, id);
    return id;
  }
  function setLatestIcpPrice(uint256 _icpPrice, address _callerAddress, uint256 _id) public {
    require(hasRole(OWNERS, msg.sender), "Not an oracle!");
    require(pendingRequests[_id], "This request is not in my pending list.");
    Response memory resp;
    resp = Response(msg.sender, _callerAddress, _icpPrice);
    requestIdToResponse[_id].push(resp);
    uint numResponses = requestIdToResponse[_id].length;
    if (numResponses == THRESHOLD) {
      uint computedIcpPrice = 0;
      for (uint f=0; f < requestIdToResponse[_id].length; f++) {
        computedIcpPrice = computedIcpPrice.add(requestIdToResponse[_id][f].icpPrice);
      }
    computedIcpPrice = computedIcpPrice.div(numResponses);
    delete pendingRequests[_id];
    delete requestIdToResponse[_id];
    CallerContractInterface callerContractInstance;
    callerContractInstance = CallerContractInterface(_callerAddress);
    callerContractInstance.callback(computedIcpPrice, _id);
    emit SetLatestIcpPriceEvent(computedIcpPrice, _callerAddress);  
    }
  }
}
