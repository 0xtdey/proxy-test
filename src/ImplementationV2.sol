// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract ImplementationV2 {
    uint256 private _value;
    
    function version() external pure returns (string memory) {
        return "V2";
    }
    
    function getValue() external view returns (uint256) {
        return _value * 2; // New implementation doubles the value
    }
    
    function setValue(uint256 newValue) external {
        _value = newValue;
    }
}

