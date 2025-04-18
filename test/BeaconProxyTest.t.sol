// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "../src/ImplementationV1.sol";
import "../src/ImplementationV2.sol";
import "../src/UpgradeableBeacon.sol";
import "../src/BeaconProxy.sol";
import "../src/BeaconProxyFactory.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract BeaconProxyTest is Test {
    MyUpgradeableBeacon beacon;
    BeaconProxyFactory factory;
    ImplementationV1 implV1;
    ImplementationV2 implV2;
    address proxy1;
    address proxy2;

    function setUp() public {
        // Deploy implementation V1
        implV1 = new ImplementationV1();

        // Deploy the upgradeable beacon with implementation V1
        beacon = new MyUpgradeableBeacon(address(implV1));

        // Deploy the factory
        factory = new BeaconProxyFactory(address(beacon));

        // Deploy V2 implementation (for later use)
        implV2 = new ImplementationV2();

        // Deploy two proxies through the factory
        proxy1 = factory.deployProxy();
        proxy2 = factory.deployProxy();
    }

    function testInitialImplementation() public view {
        assertEq(
            beacon.implementation(),
            address(implV1),
            "Beacon should point to implementation V1"
        );

        // Test if proxies are correctly delegating to implementation V1
        ImplementationV1 proxy1Impl = ImplementationV1(proxy1);
        ImplementationV1 proxy2Impl = ImplementationV1(proxy2);

        assertEq(
            proxy1Impl.version(),
            "V1",
            "Proxy1 should use V1 implementation"
        );
        assertEq(
            proxy2Impl.version(),
            "V1",
            "Proxy2 should use V1 implementation"
        );
    }

    function testProxyFunctionality() public {
        ImplementationV1 proxy1Impl = ImplementationV1(proxy1);
        ImplementationV1 proxy2Impl = ImplementationV1(proxy2);

        // Set values in each proxy
        proxy1Impl.setValue(100);
        proxy2Impl.setValue(200);

        // Check values are stored correctly
        assertEq(proxy1Impl.getValue(), 100, "Proxy1 should store value 100");
        assertEq(proxy2Impl.getValue(), 200, "Proxy2 should store value 200");
    }

    function testUpdateImplementation() public {
        // Update the beacon to point to implementation V2
        beacon.upgradeTo(address(implV2));

        // Check that the beacon now points to the new implementation
        assertEq(
            beacon.implementation(),
            address(implV2),
            "Beacon should now point to implementation V2"
        );

        // Test if proxies are now delegating to implementation V2
        ImplementationV2 proxy1Impl = ImplementationV2(proxy1);
        ImplementationV2 proxy2Impl = ImplementationV2(proxy2);

        assertEq(
            proxy1Impl.version(),
            "V2",
            "Proxy1 should now use V2 implementation"
        );
        assertEq(
            proxy2Impl.version(),
            "V2",
            "Proxy2 should now use V2 implementation"
        );
    }

    function testFunctionalityAfterUpdate() public {
        ImplementationV1 proxy1ImplV1 = ImplementationV1(proxy1);
        ImplementationV1 proxy2ImplV1 = ImplementationV1(proxy2);

        // Set values using implementation V1
        proxy1ImplV1.setValue(100);
        proxy2ImplV1.setValue(200);

        // Update to implementation V2
        beacon.upgradeTo(address(implV2));

        // Cast proxies to V2 interface
        ImplementationV2 proxy1ImplV2 = ImplementationV2(proxy1);
        ImplementationV2 proxy2ImplV2 = ImplementationV2(proxy2);

        // Check if the values are transformed according to the new implementation logic
        // In V2, getValue() returns the stored value * 2
        assertEq(
            proxy1ImplV2.getValue(),
            200,
            "Proxy1 should return double value (100*2=200) with V2"
        );
        assertEq(
            proxy2ImplV2.getValue(),
            400,
            "Proxy2 should return double value (200*2=400) with V2"
        );

        // Set new values using V2 implementation
        proxy1ImplV2.setValue(300);
        proxy2ImplV2.setValue(400);

        // Check new values with V2's multiplication
        assertEq(
            proxy1ImplV2.getValue(),
            600,
            "Proxy1 should return double value (300*2=600) with V2"
        );
        assertEq(
            proxy2ImplV2.getValue(),
            800,
            "Proxy2 should return double value (400*2=800) with V2"
        );
    }

    function testOwnershipAndAccess() public {
        // Test that only owner can update beacon implementation
        address nonOwner = address(0x123);

        // Try to update from non-owner account
        vm.startPrank(nonOwner);
        vm.expectRevert();
        beacon.upgradeTo(address(implV2));
        vm.stopPrank();

        // Verify still using V1
        ImplementationV1 proxy1Impl = ImplementationV1(proxy1);
        assertEq(
            proxy1Impl.version(),
            "V1",
            "Implementation should still be V1"
        );

        // Now update as owner
        beacon.upgradeTo(address(implV2));

        // Verify now using V2
        ImplementationV2 proxy1ImplV2 = ImplementationV2(proxy1);
        assertEq(
            proxy1ImplV2.version(),
            "V2",
            "Implementation should now be V2"
        );
    }

    function testInvalidImplementationAddress() public {
        // Test that implementation can't be zero address
        vm.expectRevert();
        beacon.upgradeTo(address(0));

        // Test that implementation must be a contract
        vm.expectRevert();
        beacon.upgradeTo(address(0x456));
    }
}
