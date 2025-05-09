// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { DeployProxiedContract } from "./utils/DeployProxiedContract.s.sol";
import { RateRegistry } from "../src/RateRegistry.sol";

contract DeployRateRegistry is DeployProxiedContract {
    function _getImplementationCreationCode() internal pure override returns (bytes memory) {
        return abi.encodePacked(type(RateRegistry).creationCode);
    }

    function _getAdminEnvVar() internal pure override returns (string memory) {
        return "XMTP_RATE_REGISTRY_ADMIN_ADDRESS";
    }

    function _getOutputFilePath() internal pure override returns (string memory) {
        return XMTP_RATE_REGISTRY_OUTPUT_JSON;
    }

    function _getProxySalt() internal pure override returns (bytes32) {
        return keccak256(abi.encodePacked("RateRegistryProxy"));
    }

    function _getImplementationSalt() internal pure override returns (bytes32) {
        return keccak256(abi.encodePacked("RateRegistry"));
    }

    function _getInitializeCalldata() internal view override returns (bytes memory) {
        address admin = vm.envAddress("XMTP_RATE_REGISTRY_ADMIN_ADDRESS");
        require(admin != address(0), "XMTP_RATE_REGISTRY_ADMIN_ADDRESS not set");

        return abi.encodeWithSelector(RateRegistry.initialize.selector, admin);
    }
}
