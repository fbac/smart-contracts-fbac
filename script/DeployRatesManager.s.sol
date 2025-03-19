// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC1967Proxy } from "../lib/oz/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { RateRegistry } from "../src/RateRegistry.sol";

import { Utils } from "./utils/Utils.sol";
import { Environment } from "./utils/Environment.sol";

contract DeployRateRegistry is Utils, Environment {
    RateRegistry implementation;
    ERC1967Proxy proxy;

    address admin;
    address deployer;

    function run() external {
        admin = vm.envAddress("XMTP_RATE_REGISTRY_ADMIN_ADDRESS");
        require(admin != address(0), "XMTP_RATE_REGISTRY_ADMIN_ADDRESS not set");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        require(privateKey != 0, "PRIVATE_KEY not set");

        deployer = vm.addr(privateKey);
        vm.startBroadcast(privateKey);

        // Deploy the implementation contract.
        implementation = new RateRegistry();
        require(address(implementation) != address(0), "Implementation deployment failed");

        // Deploy the proxy contract.
        proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(RateRegistry.initialize.selector, admin)
        );

        vm.stopBroadcast();

        _serializeDeploymentData();
    }

    function _serializeDeploymentData() internal {
        string memory parent_object = "parent object";
        string memory addresses = "addresses";

        string memory addressesOutput;

        addressesOutput = vm.serializeAddress(addresses, "deployer", deployer);
        addressesOutput = vm.serializeAddress(addresses, "proxyAdmin", admin);
        addressesOutput = vm.serializeAddress(addresses, "proxy", address(proxy));
        addressesOutput = vm.serializeAddress(addresses, "implementation", address(implementation));

        string memory finalJson;
        finalJson = vm.serializeString(parent_object, addresses, addressesOutput);
        finalJson = vm.serializeUint(parent_object, "deploymentBlock", block.number);
        finalJson = vm.serializeUint(parent_object, "latestUpgradeBlock", block.number);

        writeOutput(finalJson, XMTP_RATE_REGISTRY_OUTPUT_JSON);
    }
}
