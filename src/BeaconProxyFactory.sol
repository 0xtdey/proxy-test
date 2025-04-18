// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BeaconProxyFactory is Ownable {
    address public beacon;

    event ProxyCreated(address proxy);

    constructor(address _beacon) Ownable(msg.sender) {
        beacon = _beacon;
    }

    function setBeacon(address _beacon) external onlyOwner {
        beacon = _beacon;
    }

    function deployProxy() external returns (address) {
        BeaconProxy proxy = new BeaconProxy(
            beacon,
            ""  // No initialization data
        );
        
        emit ProxyCreated(address(proxy));
        return address(proxy);
    }
}