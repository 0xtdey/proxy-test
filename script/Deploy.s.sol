// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "lib/forge-std/src/console2.sol";
import "../src/ImplementationV1.sol";
import "../src/ImplementationV2.sol";
import "../src/UpgradeableBeacon.sol";
import "../src/BeaconProxyFactory.sol";

contract DeployBeaconProxy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy implementation V1
        ImplementationV1 implV1 = new ImplementationV1();
        console2.log("ImplementationV1 deployed at:", address(implV1));
        
        // Deploy implementation V2 (for later use)
        ImplementationV2 implV2 = new ImplementationV2();
        console2.log("ImplementationV2 deployed at:", address(implV2));
        
        // Deploy the upgradeable beacon pointing to implementation V1
        MyUpgradeableBeacon beacon = new MyUpgradeableBeacon(address(implV1));
        console2.log("UpgradeableBeacon deployed at:", address(beacon));
        
        // Deploy the factory
        BeaconProxyFactory factory = new BeaconProxyFactory(address(beacon));
        console2.log("BeaconProxyFactory deployed at:", address(factory));
        
        // Deploy two proxies
        address proxy1 = factory.deployProxy();
        console2.log("BeaconProxy 1 deployed at:", proxy1);
        
        address proxy2 = factory.deployProxy();
        console2.log("BeaconProxy 2 deployed at:", proxy2);
        
        vm.stopBroadcast();
    }
}