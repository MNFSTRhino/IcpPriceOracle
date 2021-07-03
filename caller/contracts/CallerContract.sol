// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "./IcpPriceOracleInterface.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
contract CallerContract is Ownable {
    uint256 private icpPrice;
    IcpPriceOracleInterface private oracleInstance;
    address private oracleAddress;
    mapping(uint256=>bool) myRequests;
    event newOracleAddressEvent(address oracleAddress);
    event RecievedNewRequestIdEvent(uint256 id);
    event PriceUpdatedEvent(uint256 ethPrice, uint256 id);
    function setOracleInstanceAddress(address _oracleInstnanceAddress) public onlyOwner {
        oracleAddress = _oracleInstnanceAddress;
        oracleInstance = IcpPriceOracleInterface(oracleAddress);
        emit newOracleAddressEvent(oracleAddress); 
    }
    function updateIcpPrice() public {
        uint256 id = oracleInstance.getLatestIcpPrice();
        myRequests[id] = true;
        emit RecievedNewRequestIdEvent(id);
    }
    function callback(uint256 _icpPrice, uint256 _id) public {
        require(myRequests[_id], "This request is not in my pending list");
        icpPrice = _icpPrice;
        delete myRequests[_id];
        emit PriceUpdatedEvent(_icpPrice, _id);
    }
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "You are not authorized to call this function.");
        _;
    }

}