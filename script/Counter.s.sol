// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import {ContractDeploymentInfra} from "contract-deployment-infra/ContractDeploymentInfra.sol";

contract CounterScript is Script {
    Counter public counter;

    function setUp() public {}

    function run() public {
        uint256 privateKey1 = vm.envUint("PRIVATE_KEY_1");
        uint256 privateKey2 = vm.envUint("PRIVATE_KEY_2");
        address signer1 = vm.addr(privateKey1);
        address signer2 = vm.addr(privateKey2);
        vm.startBroadcast();

        // set up multisig signers
        address[] memory signers = new address[](2);
        signers[0] = signer1;
        signers[1] = signer2;

        // deploy contract deployment infra
        ContractDeploymentInfra deploymentInfra = new ContractDeploymentInfra(signers, 1);
        address owner = deploymentInfra.owner();
        console.log("ContractDeploymentInfra deployed: ", address(deploymentInfra));

        // set up creation code
        bytes[] memory creationCode = new bytes[](2);
        creationCode[0] = abi.encodePacked(type(MintFeeManagerCore).creationCode);
        creationCode[1] = abi.encodePacked(type(SplitFeesCore).creationCode);

        // set up constructor args
        bytes[] memory constructorArgs = new bytes[](2);

        address mintFeeManagerModule = address(new MintFeeManagerModule());
        address splitFeesModule = address(new SplitFeesModule());

        address[] memory mintFeeManagerModules = new address[](1);
        bytes[] memory mintFeeManagerModuleData = new bytes[](1);
        bytes memory mintFeeManagerData = mintFeeManagerModule.encodeBytesOnInstall(owner, 300);
        mintFeeManagerModules[0] = mintFeeManagerModule;
        mintFeeManagerModuledata[0] = mintFeeManagerData;

        address[] memory splitFeesModules = new address[](1);
        bytes[] memory splitFeesModuleData = new bytes[](1);
        mintFeeManagerModules[0] = splitFeesModule;

        constructorArgs[0] = abi.encode(owner, mintFeeManagerModules, mintFeeManagerModuleData);
        constructorArgs[1] = abi.encode(owner, splitFeesModules, splitFeesModuleData);

        // prepare salt
        bytes32 salt = keccak256(abi.encodePacked("thirdweb"));

        // deploy contracts
        address[] deployedContracts = deploymentInfra.deployDeterministicBatch(creationCode, constructorArgs, salt);
        console.log("contracts deployed");
        console.log("MintFeeManagerCore deployed: ", deployedContracts[0]);
        console.log("SplitFeesCore deployed: ", deployedContracts[1]);

        vm.stopBroadcast();
    }
}
